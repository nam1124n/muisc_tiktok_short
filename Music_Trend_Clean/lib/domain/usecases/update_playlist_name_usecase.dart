import 'package:login_flutter/domain/repositories/playlist_repository.dart';

class UpdatePlaylistNameUseCase {
  final PlaylistRepository repository;

  UpdatePlaylistNameUseCase(this.repository);

  Future<void> call({
    required String userId,
    required String playlistId,
    required String name,
    required String description,
    required String coverUrl,
  }) async {
    await repository.updatePlaylistDetails(
      userId: userId,
      playlistId: playlistId,
      name: name,
      description: description,
      coverUrl: coverUrl,
    );
  }
}
