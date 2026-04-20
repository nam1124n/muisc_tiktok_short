import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/repositories/playlist_repository.dart';

class CreatePlaylistUseCase {
  final PlaylistRepository repository;

  CreatePlaylistUseCase(this.repository);

  Future<PlaylistEntity> call({
    required String userId,
    required String name,
  }) async {
    return await repository.createPlaylist(userId: userId, name: name);
  }
}
