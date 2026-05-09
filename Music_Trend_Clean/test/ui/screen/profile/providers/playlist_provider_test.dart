import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/repositories/playlist_repository.dart';
import 'package:login_flutter/domain/usecases/create_playlist_usecase.dart';
import 'package:login_flutter/domain/usecases/delete_playlist_usecase.dart';
import 'package:login_flutter/domain/usecases/get_user_playlists_usecase.dart';
import 'package:login_flutter/domain/usecases/update_playlist_name_usecase.dart';
import 'package:login_flutter/domain/usecases/update_playlist_songs_usecase.dart';
import 'package:login_flutter/ui/screen/profile/providers/playlist_provider.dart';

void main() {
  group('PlaylistNotifier', () {
    test('loadPlaylists keeps newest updated playlists first', () async {
      final repository = FakePlaylistRepository(
        playlists: [
          _playlist(
            id: 'older',
            name: 'Older',
            updatedAt: DateTime(2025, 1, 1),
          ),
          _playlist(
            id: 'newer',
            name: 'Newer',
            updatedAt: DateTime(2025, 1, 3),
          ),
        ],
      );

      final notifier = _buildNotifier(repository);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.playlists.map((item) => item.id), [
        'newer',
        'older',
      ]);
    });

    test(
      'renamePlaylist updates playlist name and moves it to the top',
      () async {
        final repository = FakePlaylistRepository(
          playlists: [
            _playlist(
              id: 'older',
              name: 'Focus',
              updatedAt: DateTime(2025, 1, 1),
            ),
            _playlist(
              id: 'newer',
              name: 'Night',
              updatedAt: DateTime(2025, 1, 2),
            ),
          ],
        );

        final notifier = _buildNotifier(repository);
        addTearDown(notifier.dispose);

        await Future<void>.delayed(Duration.zero);
        final success = await notifier.renamePlaylist(
          playlistId: 'older',
          name: 'Focus Remix',
        );

        expect(success, isTrue);
        expect(notifier.state.playlists.first.id, 'older');
        expect(notifier.state.playlists.first.name, 'Focus Remix');
      },
    );

    test('removeSongFromPlaylist removes only the target song id', () async {
      final repository = FakePlaylistRepository(
        playlists: [
          _playlist(
            id: 'mix',
            name: 'Mix',
            songIds: const ['song-1', 'song-2', 'song-3'],
            updatedAt: DateTime(2025, 1, 1),
          ),
        ],
      );

      final notifier = _buildNotifier(repository);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      final success = await notifier.removeSongFromPlaylist(
        playlistId: 'mix',
        songId: 'song-2',
      );

      expect(success, isTrue);
      expect(notifier.state.playlists.single.songIds, ['song-1', 'song-3']);
    });

    test('clearError removes the latest playlist validation error', () async {
      final repository = FakePlaylistRepository(playlists: const []);
      final notifier = _buildNotifier(repository);
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      await notifier.renamePlaylist(playlistId: 'missing', name: 'New Name');

      expect(notifier.state.errorType, PlaylistErrorType.playlistNotFound);

      notifier.clearError();

      expect(notifier.state.errorType, isNull);
      expect(notifier.state.errorMessage, isNull);
    });
  });
}

PlaylistNotifier _buildNotifier(FakePlaylistRepository repository) {
  return PlaylistNotifier(
    userId: 'user-1',
    getUserPlaylistsUseCase: GetUserPlaylistsUseCase(repository),
    createPlaylistUseCase: CreatePlaylistUseCase(repository),
    updatePlaylistNameUseCase: UpdatePlaylistNameUseCase(repository),
    updatePlaylistSongsUseCase: UpdatePlaylistSongsUseCase(repository),
    deletePlaylistUseCase: DeletePlaylistUseCase(repository),
  );
}

class FakePlaylistRepository implements PlaylistRepository {
  FakePlaylistRepository({required List<PlaylistEntity> playlists})
    : _playlists = [...playlists];

  List<PlaylistEntity> _playlists;

  @override
  Future<List<PlaylistEntity>> getUserPlaylists(String userId) async {
    return [..._playlists];
  }

  @override
  Future<PlaylistEntity> createPlaylist({
    required String userId,
    required String name,
  }) async {
    final playlist = _playlist(
      id: 'created-${_playlists.length + 1}',
      name: name,
      updatedAt: DateTime.now(),
    );
    _playlists = [playlist, ..._playlists];
    return playlist;
  }

  @override
  Future<void> updatePlaylistName({
    required String userId,
    required String playlistId,
    required String name,
  }) async {
    _playlists = [
      for (final playlist in _playlists)
        if (playlist.id == playlistId)
          playlist.copyWith(name: name, updatedAt: DateTime.now())
        else
          playlist,
    ];
  }

  @override
  Future<void> updatePlaylistSongs({
    required String userId,
    required String playlistId,
    required List<String> songIds,
  }) async {
    _playlists = [
      for (final playlist in _playlists)
        if (playlist.id == playlistId)
          playlist.copyWith(songIds: songIds, updatedAt: DateTime.now())
        else
          playlist,
    ];
  }

  @override
  Future<void> deletePlaylist({
    required String userId,
    required String playlistId,
  }) async {
    _playlists = [
      for (final playlist in _playlists)
        if (playlist.id != playlistId) playlist,
    ];
  }
}

PlaylistEntity _playlist({
  required String id,
  required String name,
  List<String> songIds = const [],
  DateTime? updatedAt,
}) {
  return PlaylistEntity(
    id: id,
    name: name,
    coverUrl: '',
    songIds: songIds,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: updatedAt,
  );
}
