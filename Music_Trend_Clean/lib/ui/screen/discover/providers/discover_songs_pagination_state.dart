import 'package:equatable/equatable.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

const _errorSentinel = Object();

class DiscoverSongsPaginationState extends Equatable {
  final List<SongEntity> songs;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? initialErrorMessage;
  final String? loadMoreErrorMessage;

  const DiscoverSongsPaginationState({
    this.songs = const [],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.initialErrorMessage,
    this.loadMoreErrorMessage,
  });

  const DiscoverSongsPaginationState.initial()
    : songs = const [],
      isInitialLoading = true,
      isLoadingMore = false,
      hasMore = true,
      initialErrorMessage = null,
      loadMoreErrorMessage = null;

  bool get hasInitialError =>
      initialErrorMessage != null &&
      initialErrorMessage!.trim().isNotEmpty &&
      songs.isEmpty;

  DiscoverSongsPaginationState copyWith({
    List<SongEntity>? songs,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? initialErrorMessage = _errorSentinel,
    Object? loadMoreErrorMessage = _errorSentinel,
  }) {
    return DiscoverSongsPaginationState(
      songs: songs ?? this.songs,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      initialErrorMessage: initialErrorMessage == _errorSentinel
          ? this.initialErrorMessage
          : initialErrorMessage as String?,
      loadMoreErrorMessage: loadMoreErrorMessage == _errorSentinel
          ? this.loadMoreErrorMessage
          : loadMoreErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    songs,
    isInitialLoading,
    isLoadingMore,
    hasMore,
    initialErrorMessage,
    loadMoreErrorMessage,
  ];
}
