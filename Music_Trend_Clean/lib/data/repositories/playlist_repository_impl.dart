import 'package:login_flutter/data/datasource/remote/playlist_remote_data_source.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/repositories/playlist_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistRemoteDataSource remoteDataSource;

  PlaylistRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PlaylistEntity>> getUserPlaylists(String userId) async {
    return await remoteDataSource.getUserPlaylists(userId);
  }

  @override
  Future<PlaylistEntity> createPlaylist({
    required String userId,
    required String name,
  }) async {
    return await remoteDataSource.createPlaylist(userId: userId, name: name);
  }

  @override
  Future<void> updatePlaylistSongs({
    required String userId,
    required String playlistId,
    required List<String> songIds,
  }) async {
    await remoteDataSource.updatePlaylistSongs(
      userId: userId,
      playlistId: playlistId,
      songIds: songIds,
    );
  }

  @override
  Future<void> deletePlaylist({
    required String userId,
    required String playlistId,
  }) async {
    await remoteDataSource.deletePlaylist(
      userId: userId,
      playlistId: playlistId,
    );
  }
}
