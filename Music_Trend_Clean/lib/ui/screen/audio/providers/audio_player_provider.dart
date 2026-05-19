import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/usecases/track_song_listen_usecase.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_state.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';

final audioPlayerNotifierProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      return AudioPlayerNotifier(
        trackSongListenUseCase: ref.read(trackSongListenUseCaseProvider),
        recordRecentSong: (song) {
          return ref.read(recentNotifierProvider.notifier).addRecent(song);
        },
        syncRecentPlayback:
            ({
              required SongEntity song,
              required Duration position,
              required Duration duration,
              required bool markCompleted,
            }) {
              return ref
                  .read(recentNotifierProvider.notifier)
                  .syncPlaybackProgress(
                    song,
                    position: position,
                    duration: duration,
                    markCompleted: markCompleted,
                  );
            },
      );
    });

final audioPlaybackForSongProvider =
    Provider.family<AudioSongPlaybackState, String>((ref, songId) {
      final playbackSnapshot = ref.watch(
        audioPlayerNotifierProvider.select(
          (state) => (
            currentSongId: state.currentSong?.id,
            isPlaying: state.isPlaying,
            isLoading: state.isLoading,
          ),
        ),
      );

      final isCurrentSong = playbackSnapshot.currentSongId == songId;
      return AudioSongPlaybackState(
        isCurrentSong: isCurrentSong,
        isPlaying: isCurrentSong && playbackSnapshot.isPlaying,
        isLoading: isCurrentSong && playbackSnapshot.isLoading,
      );
    });

final miniPlayerStateProvider = Provider<MiniPlayerState>((ref) {
  final snapshot = ref.watch(
    audioPlayerNotifierProvider.select(
      (state) => (
        currentSong: state.currentSong,
        isPlaying: state.isPlaying,
        isLoading: state.isLoading,
        canGoPrevious: state.currentIndex > 0 || state.position.inSeconds > 3,
        canGoNext: state.currentIndex < state.playlist.length - 1,
      ),
    ),
  );

  return MiniPlayerState(
    currentSong: snapshot.currentSong,
    isPlaying: snapshot.isPlaying,
    isLoading: snapshot.isLoading,
    canGoPrevious: snapshot.canGoPrevious,
    canGoNext: snapshot.canGoNext,
  );
});

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  static const Duration _defaultListenThreshold = Duration(seconds: 30);
  static const Duration _progressSyncStep = Duration(seconds: 15);

  final AudioPlayer _audioPlayer;
  final TrackSongListenUseCase _trackSongListenUseCase;
  final Future<void> Function(SongEntity song) _recordRecentSong;
  final Future<void> Function({
    required SongEntity song,
    required Duration position,
    required Duration duration,
    required bool markCompleted,
  })
  _syncRecentPlayback;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  bool _hasTrackedCurrentPlayback = false;
  int _lastSyncedProgressBucket = -1;

  AudioPlayerNotifier({
    required TrackSongListenUseCase trackSongListenUseCase,
    required Future<void> Function(SongEntity song) recordRecentSong,
    required Future<void> Function({
      required SongEntity song,
      required Duration position,
      required Duration duration,
      required bool markCompleted,
    })
    syncRecentPlayback,
  }) : _audioPlayer = AudioPlayer(),
       _trackSongListenUseCase = trackSongListenUseCase,
       _recordRecentSong = recordRecentSong,
       _syncRecentPlayback = syncRecentPlayback,
       super(const AudioPlayerState()) {
    _initStreams();
  }

  void _initStreams() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.completed) {
        unawaited(_flushCurrentProgress(markCompleted: true));
        _lastSyncedProgressBucket = -1;
        if (state.playlist.isNotEmpty &&
            state.currentIndex < state.playlist.length - 1) {
          next();
        } else if (state.isRepeatEnabled && state.playlist.isNotEmpty) {
          playAtIndex(0);
        } else {
          state = state.copyWith(isPlaying: false, position: Duration.zero);
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      } else {
        state = state.copyWith(
          isPlaying: isPlaying,
          isLoading:
              processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering,
        );
      }
    });

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(position: position);
      unawaited(_syncProgressIfNeeded(position));
      unawaited(_trackListenIfNeeded(position));
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });
  }

  Future<void> playSong(
    SongEntity song, {
    List<SongEntity>? playlist,
    Duration initialPosition = Duration.zero,
  }) async {
    try {
      final previousSong = state.currentSong;
      final previousPosition = state.position;
      final previousDuration = state.duration;
      final isSwitchingSong =
          previousSong != null && previousSong.id != song.id;
      if (isSwitchingSong) {
        unawaited(
          _syncRecentPlayback(
            song: previousSong,
            position: previousPosition,
            duration: previousDuration,
            markCompleted: false,
          ),
        );
      }

      final currentPlaylist = playlist ?? state.playlist;
      final index = currentPlaylist.indexWhere((s) => s.id == song.id);
      _hasTrackedCurrentPlayback = false;
      _lastSyncedProgressBucket = -1;

      state = state.copyWith(
        currentSong: song,
        playlist: currentPlaylist,
        currentIndex: index != -1 ? index : 0,
        isLoading: true,
        isError: false,
        position: Duration.zero,
        duration: Duration.zero,
      );

      await _audioPlayer.setUrl(song.audioUrl);
      if (initialPosition > Duration.zero) {
        await _audioPlayer.seek(initialPosition);
        state = state.copyWith(position: initialPosition);
      }
      unawaited(_recordRecentSong(song));
      _audioPlayer.play();
    } catch (e) {
      state = state.copyWith(isError: true, isLoading: false);
    }
  }

  void pause() {
    _audioPlayer.pause();
    unawaited(_flushCurrentProgress());
  }

  void resume() {
    _audioPlayer.play();
  }

  void seek(Duration position) {
    _lastSyncedProgressBucket = -1;
    _audioPlayer.seek(position);
    state = state.copyWith(position: position);
    unawaited(_flushCurrentProgress(positionOverride: position));
  }

  Future<void> next() async {
    if (state.playlist.isEmpty) return;

    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.playlist.length) {
      final nextSong = state.playlist[nextIndex];
      await playSong(nextSong, playlist: state.playlist);
    } else if (state.isRepeatEnabled) {
      await playAtIndex(0);
    }
  }

  Future<void> previous() async {
    if (state.playlist.isEmpty) return;

    if (state.position.inSeconds > 3) {
      // If played more than 3 seconds, previous goes to start of current song
      await _audioPlayer.seek(Duration.zero);
    } else {
      final prevIndex = state.currentIndex - 1;
      if (prevIndex >= 0) {
        final prevSong = state.playlist[prevIndex];
        await playSong(prevSong, playlist: state.playlist);
      } else {
        await _audioPlayer.seek(Duration.zero);
      }
    }
  }

  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= state.playlist.length) {
      return;
    }

    await playSong(state.playlist[index], playlist: state.playlist);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.playlist.length) {
      return;
    }

    if (index == state.currentIndex) {
      return;
    }

    final playlist = [...state.playlist]..removeAt(index);
    final nextIndex = index < state.currentIndex
        ? state.currentIndex - 1
        : state.currentIndex;
    state = state.copyWith(playlist: playlist, currentIndex: nextIndex);
  }

  void moveQueueItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.playlist.length ||
        newIndex < 0 ||
        newIndex > state.playlist.length ||
        oldIndex == state.currentIndex) {
      return;
    }

    final playlist = [...state.playlist];
    final currentSong = state.currentSong;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (newIndex == state.currentIndex) {
      newIndex = oldIndex < state.currentIndex
          ? state.currentIndex - 1
          : state.currentIndex + 1;
    }

    if (newIndex < 0 || newIndex >= playlist.length) {
      return;
    }

    final item = playlist.removeAt(oldIndex);
    playlist.insert(newIndex, item);
    final nextCurrentIndex = currentSong == null
        ? -1
        : playlist.indexWhere((song) => song.id == currentSong.id);
    state = state.copyWith(playlist: playlist, currentIndex: nextCurrentIndex);
  }

  void toggleShuffle() {
    final enableShuffle = !state.isShuffleEnabled;
    final currentSong = state.currentSong;

    if (!enableShuffle || currentSong == null || state.playlist.length <= 2) {
      state = state.copyWith(isShuffleEnabled: enableShuffle);
      return;
    }

    final played = state.playlist.take(state.currentIndex + 1).toList();
    final nextUp = state.playlist.skip(state.currentIndex + 1).toList()
      ..shuffle();
    state = state.copyWith(
      playlist: [...played, ...nextUp],
      currentIndex: played.indexWhere((song) => song.id == currentSong.id),
      isShuffleEnabled: true,
    );
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeatEnabled: !state.isRepeatEnabled);
  }

  Future<void> _trackListenIfNeeded(Duration position) async {
    if (_hasTrackedCurrentPlayback) {
      return;
    }

    final song = state.currentSong;
    if (song == null || !song.trackInWeeklyStats) {
      return;
    }

    final threshold = _listenThresholdFor(state.duration);
    if (position < threshold) {
      return;
    }

    _hasTrackedCurrentPlayback = true;

    try {
      await _trackSongListenUseCase(song);
    } catch (_) {
      _hasTrackedCurrentPlayback = false;
    }
  }

  Future<void> _syncProgressIfNeeded(Duration position) async {
    final song = state.currentSong;
    if (song == null || state.duration == Duration.zero || !state.isPlaying) {
      return;
    }

    final bucket = position.inSeconds ~/ _progressSyncStep.inSeconds;
    if (bucket <= _lastSyncedProgressBucket || bucket <= 0) {
      return;
    }

    _lastSyncedProgressBucket = bucket;
    await _syncRecentPlayback(
      song: song,
      position: position,
      duration: state.duration,
      markCompleted: false,
    );
  }

  Future<void> _flushCurrentProgress({
    bool markCompleted = false,
    Duration? positionOverride,
  }) async {
    final song = state.currentSong;
    if (song == null) {
      return;
    }

    final duration = state.duration;
    final position = markCompleted
        ? (duration == Duration.zero ? state.position : duration)
        : (positionOverride ?? state.position);
    if (!markCompleted &&
        position <= Duration.zero &&
        duration == Duration.zero) {
      return;
    }

    await _syncRecentPlayback(
      song: song,
      position: position,
      duration: duration,
      markCompleted: markCompleted,
    );
  }

  Duration _listenThresholdFor(Duration duration) {
    if (duration == Duration.zero || duration >= _defaultListenThreshold) {
      return _defaultListenThreshold;
    }

    return Duration(milliseconds: (duration.inMilliseconds * 0.6).round());
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class AudioSongPlaybackState extends Equatable {
  const AudioSongPlaybackState({
    required this.isCurrentSong,
    required this.isPlaying,
    required this.isLoading,
  });

  final bool isCurrentSong;
  final bool isPlaying;
  final bool isLoading;

  @override
  List<Object?> get props => [isCurrentSong, isPlaying, isLoading];
}

class MiniPlayerState extends Equatable {
  const MiniPlayerState({
    required this.currentSong,
    required this.isPlaying,
    required this.isLoading,
    required this.canGoPrevious,
    required this.canGoNext,
  });

  final SongEntity? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final bool canGoPrevious;
  final bool canGoNext;

  @override
  List<Object?> get props => [
    currentSong,
    isPlaying,
    isLoading,
    canGoPrevious,
    canGoNext,
  ];
}
