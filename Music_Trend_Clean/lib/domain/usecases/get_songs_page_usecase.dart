import 'package:login_flutter/domain/entities/song_page_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';

class GetSongsPageUseCase {
  const GetSongsPageUseCase(this.repository);

  final SongRepository repository;

  Future<SongPageEntity> call({int limit = 20, SongPageCursor? startAfter}) {
    return repository.fetchSongsPage(limit: limit, startAfter: startAfter);
  }
}
