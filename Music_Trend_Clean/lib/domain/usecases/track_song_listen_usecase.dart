import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';

class TrackSongListenUseCase {
  final SongRepository repository;

  TrackSongListenUseCase(this.repository);

  Future<void> call(SongEntity song) {
    return repository.trackSongListen(song);
  }
}
