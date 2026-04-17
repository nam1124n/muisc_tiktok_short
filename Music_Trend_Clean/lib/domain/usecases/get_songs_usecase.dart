import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';

class GetSongsUseCase {
  final SongRepository repository;
  GetSongsUseCase(this.repository);

  Stream<List<SongEntity>> call() => repository.getSongs();
}
