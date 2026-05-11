import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/year_song_repository.dart';

class GetAdminYearSongsUseCase {
  final YearSongRepository repository;

  GetAdminYearSongsUseCase(this.repository);

  Stream<List<SongEntity>> call() => repository.getAdminSongs();
}
