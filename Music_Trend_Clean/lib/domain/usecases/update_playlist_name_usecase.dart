import 'package:login_flutter/domain/repositories/playlist_repository.dart';

class UpdatePlaylistNameUseCase {
  final PlaylistRepository repository;

  UpdatePlaylistNameUseCase(this.repository);

  Future<void> call({
    required String userId,
    required String playlistId,
    required String name,
  }) async {
    await repository.updatePlaylistName(
      userId: userId,
      playlistId: playlistId,
      name: name,
    );
  }
}
