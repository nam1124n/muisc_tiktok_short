import 'package:login_flutter/domain/repositories/song_repository.dart';

class DeleteSongUseCase {
  final SongRepository repository;
  DeleteSongUseCase(this.repository);

  Future<void> call(String id) => repository.deleteSong(id);
}
