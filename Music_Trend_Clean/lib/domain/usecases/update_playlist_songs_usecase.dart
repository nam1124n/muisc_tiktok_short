import 'package:login_flutter/domain/repositories/playlist_repository.dart';

class UpdatePlaylistSongsUseCase {
  final PlaylistRepository repository;

  UpdatePlaylistSongsUseCase(this.repository);

  Future<void> call({
    required String userId,
    required String playlistId,
    required List<String> songIds,
  }) async {
    await repository.updatePlaylistSongs(
      userId: userId,
      playlistId: playlistId,
      songIds: songIds,
    );
  }
}
