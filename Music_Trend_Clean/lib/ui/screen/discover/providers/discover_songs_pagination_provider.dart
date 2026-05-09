import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/usecases/get_songs_page_usecase.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/discover_songs_pagination_state.dart';

final discoverSongsPaginationProvider =
    StateNotifierProvider<
      DiscoverSongsPaginationNotifier,
      DiscoverSongsPaginationState
    >((ref) {
      return DiscoverSongsPaginationNotifier(
        getSongsPageUseCase: ref.read(getSongsPageUseCaseProvider),
      );
    });

class DiscoverSongsPaginationNotifier
    extends StateNotifier<DiscoverSongsPaginationState> {
  static const int _pageSize = 20;

  final GetSongsPageUseCase getSongsPageUseCase;
  SongPageCursor? _nextCursor;

  DiscoverSongsPaginationNotifier({
    required this.getSongsPageUseCase,
    bool autoLoad = true,
  }) : super(const DiscoverSongsPaginationState.initial()) {
    if (autoLoad) {
      loadInitial();
    }
  }

  Future<void> refresh() => loadInitial();

  Future<void> loadInitial() async {
    _nextCursor = null;
    state = state.copyWith(
      songs: const [],
      isInitialLoading: true,
      isLoadingMore: false,
      hasMore: true,
      initialErrorMessage: null,
      loadMoreErrorMessage: null,
    );

    try {
      final page = await getSongsPageUseCase(limit: _pageSize);
      if (!mounted) return;

      _nextCursor = page.nextCursor;
      state = state.copyWith(
        songs: page.songs,
        isInitialLoading: false,
        hasMore: page.hasMore,
        initialErrorMessage: null,
        loadMoreErrorMessage: null,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        songs: const [],
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: false,
        initialErrorMessage: ErrorMessageMapper.map(error),
        loadMoreErrorMessage: null,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, loadMoreErrorMessage: null);

    try {
      final page = await getSongsPageUseCase(
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
