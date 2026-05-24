import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/usecases/get_feed_songs_page_usecase.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(
    getFeedSongsPageUseCase: ref.read(getFeedSongsPageUseCaseProvider),
  );
});

const _feedStateNoChange = Object();

class FeedState extends Equatable {
  const FeedState({
    this.songs = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.initialErrorMessage,
    this.loadMoreErrorMessage,
  });

  const FeedState.initial()
    : songs = const [],
      isInitialLoading = true,
      isRefreshing = false,
      isLoadingMore = false,
      hasMore = true,
      initialErrorMessage = null,
      loadMoreErrorMessage = null;

  final List<SongEntity> songs;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final String? initialErrorMessage;
  final String? loadMoreErrorMessage;

  bool get hasInitialError =>
      initialErrorMessage != null &&
      initialErrorMessage!.trim().isNotEmpty &&
      songs.isEmpty;

  bool get hasLoadMoreError =>
      loadMoreErrorMessage != null &&
      loadMoreErrorMessage!.trim().isNotEmpty &&
      songs.isNotEmpty;

  bool get isEmpty => songs.isEmpty && !isInitialLoading && !hasInitialError;

  FeedState copyWith({
    List<SongEntity>? songs,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    Object? initialErrorMessage = _feedStateNoChange,
    Object? loadMoreErrorMessage = _feedStateNoChange,
  }) {
    return FeedState(
      songs: songs ?? this.songs,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      initialErrorMessage: initialErrorMessage == _feedStateNoChange
          ? this.initialErrorMessage
          : initialErrorMessage as String?,
      loadMoreErrorMessage: loadMoreErrorMessage == _feedStateNoChange
          ? this.loadMoreErrorMessage
          : loadMoreErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    songs,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    hasMore,
    initialErrorMessage,
    loadMoreErrorMessage,
  ];
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier({
    required this.getFeedSongsPageUseCase,
    bool autoLoad = true,
  }) : super(const FeedState.initial()) {
    if (autoLoad) {
      loadInitial();
    }
  }

  static const int _pageSize = 12;

  final GetFeedSongsPageUseCase getFeedSongsPageUseCase;
  SongPageCursor? _nextCursor;

  Future<void> refresh() => loadInitial(keepSongs: true);

  Future<void> loadInitial({bool keepSongs = false}) async {
    _nextCursor = null;
    state = state.copyWith(
      songs: keepSongs ? state.songs : const [],
      isInitialLoading: !keepSongs,
      isRefreshing: keepSongs,
      isLoadingMore: false,
      hasMore: true,
      initialErrorMessage: null,
      loadMoreErrorMessage: null,
    );

    try {
      final page = await getFeedSongsPageUseCase(limit: _pageSize);
      if (!mounted) return;

      _nextCursor = page.nextCursor;
      state = state.copyWith(
        songs: page.songs,
        isInitialLoading: false,
        isRefreshing: false,
        hasMore: page.hasMore,
        initialErrorMessage: null,
        loadMoreErrorMessage: null,
      );
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        hasMore: state.songs.isNotEmpty,
        initialErrorMessage: state.songs.isEmpty
            ? ErrorMessageMapper.map(error)
            : null,
        loadMoreErrorMessage: state.songs.isNotEmpty
            ? ErrorMessageMapper.map(error)
            : null,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, loadMoreErrorMessage: null);

    try {
      final page = await getFeedSongsPageUseCase(
        limit: _pageSize,
        startAfter: _nextCursor,
      );
      if (!mounted) return;

      _nextCursor = page.nextCursor ?? _nextCursor;
      state = state.copyWith(
        songs: _mergeSongs(state.songs, page.songs),
        isLoadingMore: false,
        hasMore: page.hasMore,
        loadMoreErrorMessage: null,
      );
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(
        isLoadingMore: false,
        loadMoreErrorMessage: ErrorMessageMapper.map(error),
      );
    }
  }

  Future<void> retryLoadMore() => loadMore();

  void hideSong(String songId) {
    final nextSongs = [
      for (final song in state.songs)
        if (song.id != songId) song,
    ];

    if (nextSongs.length == state.songs.length) {
      return;
    }

    state = state.copyWith(songs: nextSongs);
  }

  List<SongEntity> _mergeSongs(
    List<SongEntity> current,
    List<SongEntity> incoming,
  ) {
    final songsById = <String, SongEntity>{
      for (final song in current) song.id: song,
    };

    for (final song in incoming) {
      songsById[song.id] = song;
    }

    return songsById.values.toList();
  }
}
