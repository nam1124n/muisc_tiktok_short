import 'package:equatable/equatable.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

class AudioPlayerState extends Equatable {
  final SongEntity? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final bool isError;
  final Duration position;
  final Duration duration;
  final List<SongEntity> playlist;
  final int currentIndex;

  const AudioPlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.isError = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playlist = const [],
    this.currentIndex = -1,
  });

  AudioPlayerState copyWith({
    SongEntity? currentSong,
    bool? isPlaying,
    bool? isLoading,
    bool? isError,
    Duration? position,
    Duration? duration,
    List<SongEntity>? playlist,
    int? currentIndex,
  }) {
    return AudioPlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [
    currentSong,
    isPlaying,
    isLoading,
    isError,
    position,
    duration,
    playlist,
    currentIndex,
  ];
}
