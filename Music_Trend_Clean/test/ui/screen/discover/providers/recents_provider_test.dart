import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/domain/entities/listening_history_entry_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';

void main() {
  group('RecentNotifier', () {
    test(
      'loads recent songs in descending timestamp order without duplicates',
      () async {
        final repository = FakeInteractionRepository(
          entries: [
            _entry(
              song: _song(
                id: 'older',
                title: 'Older',
                savedAt: DateTime(2025, 1, 1),
              ),
            ),
            _entry(
              song: _song(
                id: 'newer',
                title: 'Newer',
                savedAt: DateTime(2025, 1, 3),
              ),
            ),
            _entry(
              song: _song(
                id: 'older',
                title: 'Older refreshed',
                savedAt: DateTime(2025, 1, 4),
              ),
            ),
          ],
        );

        final notifier = RecentNotifier(
          userId: 'user-1',
          repository: repository,
        );
        addTearDown(notifier.dispose);

        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.songs.map((song) => song.id), ['older', 'newer']);
        expect(notifier.state.songs.first.title, 'Older refreshed');
      },
    );

    test('addRecent moves song to the top and saves it remotely', () async {
      final repository = FakeInteractionRepository(
        entries: [
          _entry(
            song: _song(
              id: 'song-1',
              title: 'Song 1',
              savedAt: DateTime(2025, 1, 1),
            ),
            playCount: 1,
          ),
          _entry(
            song: _song(
              id: 'song-2',
              title: 'Song 2',
              savedAt: DateTime(2025, 1, 2),
            ),
            playCount: 3,
          ),
        ],
      );

      final notifier = RecentNotifier(userId: 'user-1', repository: repository);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      await notifier.addRecent(_song(id: 'song-1', title: 'Song 1 replayed'));

      expect(notifier.state.songs.first.id, 'song-1');
      expect(repository.addedRecentSongIds, ['song-1']);
      expect(notifier.state.mostPlayed.first.song.id, 'song-2');
    });

    test(
      'clearRecents removes all songs and clears remote documents',
      () async {
        final repository = FakeInteractionRepository(
          entries: [
            _entry(
              song: _song(id: 'song-1', title: 'Song 1'),
            ),
            _entry(
              song: _song(id: 'song-2', title: 'Song 2'),
            ),
          ],
        );

        final notifier = RecentNotifier(
          userId: 'user-1',
          repository: repository,
        );
        addTearDown(notifier.dispose);

        await Future<void>.delayed(Duration.zero);
        await notifier.clearRecents();

        expect(notifier.state.songs, isEmpty);
        expect(repository.clearedRecentIds, ['song-1', 'song-2']);
      },
    );

    test('syncPlaybackProgress exposes continue listening entries', () async {
      final repository = FakeInteractionRepository(
        entries: [
          _entry(
            song: _song(id: 'song-1', title: 'Song 1'),
          ),
        ],
      );

      final notifier = RecentNotifier(userId: 'user-1', repository: repository);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      await notifier.syncPlaybackProgress(
        _song(id: 'song-1', title: 'Song 1'),
        position: const Duration(seconds: 42),
        duration: const Duration(minutes: 3),
      );

      expect(notifier.state.continueListening, hasLength(1));
      expect(repository.syncedProgressSongIds, ['song-1']);
    });
  });
}

class FakeInteractionRepository implements InteractionRepository {
  FakeInteractionRepository({
    required List<ListeningHistoryEntryEntity> entries,
  }) : _entries = [...entries];

  List<ListeningHistoryEntryEntity> _entries;
  final List<String> addedRecentSongIds = [];
  List<String> clearedRecentIds = const [];
  final List<String> syncedProgressSongIds = [];

  @override
  Future<List<ListeningHistoryEntryEntity>> getHistoryEntries(
    String userId,
  ) async {
    return [..._entries];
  }

  @override
  Future<void> addRecent(String userId, SongEntity song) async {
    addedRecentSongIds.add(song.id);
    final current = _firstEntryBySongId(song.id);
    _entries = [
      ListeningHistoryEntryEntity(
        song: song,
        lastPlayedAt: song.savedAt,
        playCount: (current?.playCount ?? 0) + 1,
        completedCount: current?.completedCount ?? 0,
        lastPosition: current?.lastPosition ?? Duration.zero,
        duration: current?.duration ?? Duration.zero,
      ),
      for (final item in _entries)
        if (item.song.id != song.id) item,
    ];
  }

  @override
  Future<void> updateRecentProgress(
    String userId,
    SongEntity song, {
    required Duration position,
    required Duration duration,
    bool markCompleted = false,
  }) async {
    syncedProgressSongIds.add(song.id);
    final current = _firstEntryBySongId(song.id);
    final playCount = current?.playCount ?? 1;
    final completedCount =
        (current?.completedCount ?? 0) + (markCompleted ? 1 : 0);

    _entries = [
      ListeningHistoryEntryEntity(
        song: song,
        lastPlayedAt: song.savedAt,
        playCount: playCount,
        completedCount: completedCount,
        lastPosition: markCompleted ? Duration.zero : position,
        duration: duration,
      ),
      for (final item in _entries)
        if (item.song.id != song.id) item,
    ];
  }

  @override
  Future<void> clearRecents(String userId, List<String> songIds) async {
    clearedRecentIds = [...songIds];
    _entries = const [];
  }

  @override
  Future<List<SongEntity>> getFavorites(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<void> toggleFavorite(String userId, SongEntity song, bool isFavorite) {
    throw UnimplementedError();
  }

  @override
  Future<void> clearFavorites(String userId, List<String> songIds) {
    throw UnimplementedError();
  }

  ListeningHistoryEntryEntity? _firstEntryBySongId(String songId) {
    for (final entry in _entries) {
      if (entry.song.id == songId) {
        return entry;
      }
    }

    return null;
  }
}

ListeningHistoryEntryEntity _entry({
  required SongEntity song,
  int playCount = 1,
  int completedCount = 0,
  Duration lastPosition = Duration.zero,
  Duration duration = Duration.zero,
}) {
  return ListeningHistoryEntryEntity(
    song: song,
    lastPlayedAt: song.savedAt,
    playCount: playCount,
    completedCount: completedCount,
    lastPosition: lastPosition,
    duration: duration,
  );
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
