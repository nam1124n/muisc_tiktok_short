import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/usecases/track_song_listen_usecase.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_state.dart';

final audioPlayerNotifierProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      return AudioPlayerNotifier(
        trackSongListenUseCase: ref.read(trackSongListenUseCaseProvider),
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

  final AudioPlayer _audioPlayer;
  final TrackSongListenUseCase _trackSongListenUseCase;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  bool _hasTrackedCurrentPlayback = false;

  AudioPlayerNotifier({required TrackSongListenUseCase trackSongListenUseCase})
    : _audioPlayer = AudioPlayer(),
      _trackSongListenUseCase = trackSongListenUseCase,
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
        if (state.playlist.isNotEmpty &&
            state.currentIndex < state.playlist.length - 1) {
          next();
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
      unawaited(_trackListenIfNeeded(position));
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });
  }

  Future<void> playSong(SongEntity song, {List<SongEntity>? playlist}) async {
    try {
      final currentPlaylist = playlist ?? state.playlist;
      final index = currentPlaylist.indexWhere((s) => s.id == song.id);
      _hasTrackedCurrentPlayback = false;

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
      _audioPlayer.play();
    } catch (e) {
      state = state.copyWith(isError: true, isLoading: false);
    }
  }

  void pause() {
    _audioPlayer.pause();
  }

  void resume() {
    _audioPlayer.play();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  Future<void> next() async {
    if (state.playlist.isEmpty) return;

    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.playlist.length) {
      final nextSong = state.playlist[nextIndex];
      await playSong(nextSong, playlist: state.playlist);
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
