import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';

class GetFeedSongsPageUseCase {
  const GetFeedSongsPageUseCase(this.repository);

  final SongRepository repository;

  Future<SongPageEntity> call({int limit = 20, SongPageCursor? startAfter}) {
    return repository.fetchFeedSongsPage(limit: limit, startAfter: startAfter);
  }
}
