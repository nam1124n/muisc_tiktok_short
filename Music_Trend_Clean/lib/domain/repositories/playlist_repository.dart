import 'package:login_flutter/domain/entities/playlist_entity.dart';

abstract class PlaylistRepository {
  Future<List<PlaylistEntity>> getUserPlaylists(String userId);
  Future<PlaylistEntity> createPlaylist({
    required String userId,
    required String name,
  });
  Future<void> updatePlaylistDetails({
    required String userId,
    required String playlistId,
    required String name,
    required String description,
    required String coverUrl,
  });
  Future<void> updatePlaylistSongs({
    required String userId,
    required String playlistId,
    required List<String> songIds,
  });
  Future<void> deletePlaylist({
    required String userId,
    required String playlistId,
  });
}
