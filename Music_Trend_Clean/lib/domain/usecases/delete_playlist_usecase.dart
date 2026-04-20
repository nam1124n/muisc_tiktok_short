import 'package:login_flutter/domain/repositories/playlist_repository.dart';

class DeletePlaylistUseCase {
  final PlaylistRepository repository;

  DeletePlaylistUseCase(this.repository);

  Future<void> call({
    required String userId,
    required String playlistId,
  }) async {
    await repository.deletePlaylist(userId: userId, playlistId: playlistId);
  }
}
