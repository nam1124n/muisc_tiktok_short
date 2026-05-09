import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';

void main() {
  group('FavoriteNotifier', () {
    test('loads favorites in timestamp order without duplicates', () async {
      final repository = FakeInteractionRepository(
        favorites: [
          _song(id: 'older', title: 'Older', savedAt: DateTime(2025, 1, 1)),
          _song(id: 'newer', title: 'Newer', savedAt: DateTime(2025, 1, 3)),
          _song(
            id: 'older',
            title: 'Older refreshed',
            savedAt: DateTime(2025, 1, 4),
          ),
        ],
      );

      final notifier = FavoriteNotifier(
        userId: 'user-1',
        repository: repository,
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.songs.map((song) => song.id), ['older', 'newer']);
      expect(notifier.state.songs.first.title, 'Older refreshed');
    });

    test(
      'toggleFavorite removes an existing favorite optimistically',
      () async {
        final song = _song(id: 'song-1', title: 'Song 1');
        final repository = FakeInteractionRepository(favorites: [song]);
        final notifier = FavoriteNotifier(
          userId: 'user-1',
          repository: repository,
        );
        addTearDown(notifier.dispose);

        await Future<void>.delayed(Duration.zero);
        await notifier.toggleFavorite(song);

        expect(notifier.state.songs, isEmpty);
        expect(repository.toggledFavorites, [('song-1', false)]);
      },
    );

    test(
      'clearFavorites removes all favorites and clears remote documents',
      () async {
        final repository = FakeInteractionRepository(
          favorites: [
            _song(id: 'song-1', title: 'Song 1'),
            _song(id: 'song-2', title: 'Song 2'),
          ],
        );
        final notifier = FavoriteNotifier(
          userId: 'user-1',
          repository: repository,
        );
        addTearDown(notifier.dispose);

        await Future<void>.delayed(Duration.zero);
        await notifier.clearFavorites();

        expect(notifier.state.songs, isEmpty);
        expect(repository.clearedFavoriteIds, ['song-1', 'song-2']);
      },
    );
  });
}

class FakeInteractionRepository implements InteractionRepository {
  FakeInteractionRepository({required List<SongEntity> favorites})
    : _favorites = [...favorites];

  List<SongEntity> _favorites;
  final List<(String, bool)> toggledFavorites = [];
  List<String> clearedFavoriteIds = const [];

  @override
  Future<List<SongEntity>> getFavorites(String userId) async {
    return [..._favorites];
  }

  @override
  Future<void> toggleFavorite(
    String userId,
    SongEntity song,
    bool isFavorite,
  ) async {
    toggledFavorites.add((song.id, isFavorite));
    if (isFavorite) {
      _favorites = [song, ..._favorites.where((item) => item.id != song.id)];
      return;
    }

    _favorites = [
      for (final item in _favorites)
        if (item.id != song.id) item,
    ];
  }

  @override
  Future<void> clearFavorites(String userId, List<String> songIds) async {
    clearedFavoriteIds = [...songIds];
    _favorites = const [];
  }

  @override
  Future<List<SongEntity>> getRecents(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<void> addRecent(String userId, SongEntity song) {
    throw UnimplementedError();
  }
}

SongEntity _song({
  required String id,
  required String title,
  DateTime? savedAt,
}) {
  return SongEntity(
    id: id,
    title: title,
    artist: 'Artist',
    audioUrl: 'audio-url',
    imageUrl: 'image-url',
    savedAt: savedAt,
  );
}
