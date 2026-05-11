import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';

class GetAdminSongsUseCase {
  final SongRepository repository;

  GetAdminSongsUseCase(this.repository);

  Stream<List<SongEntity>> call() => repository.getAdminSongs();
}
