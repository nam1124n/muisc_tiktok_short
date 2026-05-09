import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';
import 'package:login_flutter/domain/usecases/get_songs_page_usecase.dart';
import 'package:login_flutter/ui/screen/discover/providers/discover_songs_pagination_provider.dart';

void main() {
  group('DiscoverSongsPaginationNotifier', () {
    test('loadInitial fills the first page', () async {
      final repository = FakeSongRepository(
        pageResponses: [
          SongPageEntity(
            songs: [_song('1', 'Alpha'), _song('2', 'Bravo')],
            nextCursor: const SongPageCursor(title: 'Bravo', id: '2'),
            hasMore: true,
          ),
        ],
      );
      final notifier = DiscoverSongsPaginationNotifier(
        getSongsPageUseCase: GetSongsPageUseCase(repository),
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      await notifier.loadInitial();

      expect(notifier.state.isInitialLoading, isFalse);
      expect(notifier.state.songs.map((song) => song.id), ['1', '2']);
      expect(notifier.state.hasMore, isTrue);
    });

    test('loadMore appends the next page and updates hasMore', () async {
      final repository = FakeSongRepository(
        pageResponses: [
          SongPageEntity(
            songs: [_song('1', 'Alpha')],
            nextCursor: const SongPageCursor(title: 'Alpha', id: '1'),
            hasMore: true,
          ),
          SongPageEntity(
            songs: [_song('2', 'Bravo')],
            nextCursor: const SongPageCursor(title: 'Bravo', id: '2'),
            hasMore: false,
          ),
        ],
      );
      final notifier = DiscoverSongsPaginationNotifier(
        getSongsPageUseCase: GetSongsPageUseCase(repository),
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      await notifier.loadInitial();
      await notifier.loadMore();

      expect(notifier.state.songs.map((song) => song.id), ['1', '2']);
      expect(notifier.state.hasMore, isFalse);
      expect(repository.requestedCursors, [
        null,
        const SongPageCursor(title: 'Alpha', id: '1'),
      ]);
    });

    test('retryLoadMore recovers after a load-more failure', () async {
      final repository = FakeSongRepository(
        pageResponses: [
          SongPageEntity(
            songs: [_song('1', 'Alpha')],
            nextCursor: const SongPageCursor(title: 'Alpha', id: '1'),
            hasMore: true,
          ),
          Exception('load-more failed'),
          SongPageEntity(
            songs: [_song('2', 'Bravo')],
            nextCursor: null,
            hasMore: false,
          ),
        ],
      );
      final notifier = DiscoverSongsPaginationNotifier(
        getSongsPageUseCase: GetSongsPageUseCase(repository),
        autoLoad: false,
      );
      addTearDown(notifier.dispose);

      await notifier.loadInitial();
      await notifier.loadMore();
      expect(notifier.state.loadMoreErrorMessage, 'load-more failed');

      await notifier.retryLoadMore();
      expect(notifier.state.loadMoreErrorMessage, isNull);
      expect(notifier.state.songs.map((song) => song.id), ['1', '2']);
    });
  });
}

class FakeSongRepository implements SongRepository {
  FakeSongRepository({required this.pageResponses});

  final List<Object> pageResponses;
  final List<SongPageCursor?> requestedCursors = [];

  @override
  Future<SongPageEntity> fetchSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) async {
    requestedCursors.add(startAfter);
    final response = pageResponses.removeAt(0);
    if (response is Exception) {
      throw response;
    }

    return response as SongPageEntity;
  }

  @override
  Stream<List<SongEntity>> getSongs() => const Stream.empty();

  @override
  Stream<List<TrendingSongEntity>> getWeeklyTrendingSongs({int limit = 4}) {
    return const Stream.empty();
  }

  @override
  Future<void> addSong(SongEntity song, XFile imageFile, XFile audioFile) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSong(
    SongEntity song, {
    XFile? imageFile,
    XFile? audioFile,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSong(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> trackSongListen(SongEntity song) {
    throw UnimplementedError();
  }
}

SongEntity _song(String id, String title) {
  return SongEntity(
    id: id,
    title: title,
    artist: 'Artist $id',
    audioUrl: 'audio-$id',
    imageUrl: 'image-$id',
  );
}
