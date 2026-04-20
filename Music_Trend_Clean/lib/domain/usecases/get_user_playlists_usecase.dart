import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/repositories/playlist_repository.dart';

class GetUserPlaylistsUseCase {
  final PlaylistRepository repository;

  GetUserPlaylistsUseCase(this.repository);

  Future<List<PlaylistEntity>> call(String userId) async {
    return await repository.getUserPlaylists(userId);
  }
}
