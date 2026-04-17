import 'package:login_flutter/domain/repositories/year_song_repository.dart';

class DeleteYearSongUseCase {
  final YearSongRepository repository;

  DeleteYearSongUseCase(this.repository);

  Future<void> call(String id) => repository.deleteSong(id);
}
