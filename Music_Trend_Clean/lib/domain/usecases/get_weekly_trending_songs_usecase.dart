import 'package:login_flutter/domain/repositories/song_repository.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';

class GetWeeklyTrendingSongsUseCase {
  final SongRepository repository;

  GetWeeklyTrendingSongsUseCase(this.repository);

  Stream<List<TrendingSongEntity>> call({int limit = 4}) {
    return repository.getWeeklyTrendingSongs(limit: limit);
  }
}
