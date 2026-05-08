import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/data/datasource/remote/song_remote_data_source.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/discover_songs_pagination_state.dart';

final discoverSongsPaginationProvider =
    StateNotifierProvider<
      DiscoverSongsPaginationNotifier,
      DiscoverSongsPaginationState
    >((ref) {
      return DiscoverSongsPaginationNotifier(
        remoteDataSource: ref.read(songRemoteDataSourceProvider),
      );
    });

class DiscoverSongsPaginationNotifier
    extends StateNotifier<DiscoverSongsPaginationState> {
  static const int _pageSize = 20;

  final SongRemoteDataSource remoteDataSource;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  DiscoverSongsPaginationNotifier({required this.remoteDataSource})
    : super(const DiscoverSongsPaginationState.initial()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    _lastDocument = null;
    state = state.copyWith(
      songs: const [],
      isInitialLoading: true,
      isLoadingMore: false,
      hasMore: true,
      initialErrorMessage: null,
      loadMoreErrorMessage: null,
    );

    try {
      final page = await remoteDataSource.fetchSongsPage(limit: _pageSize);
      if (!mounted) return;

      _lastDocument = page.lastDocument;
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
        initialErrorMessage: _readableError(error),
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
      final page = await remoteDataSource.fetchSongsPage(
        limit: _pageSize,
        startAfterDocument: _lastDocument,
      );
      if (!mounted) return;

      _lastDocument = page.lastDocument ?? _lastDocument;
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
        loadMoreErrorMessage: _readableError(error),
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

  String _readableError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
