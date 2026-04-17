import 'package:image_picker/image_picker.dart';

import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';

abstract class SongRepository {
  Stream<List<SongEntity>> getSongs();
  Stream<List<TrendingSongEntity>> getWeeklyTrendingSongs({int limit = 4});
  Future<void> addSong(SongEntity song, XFile imageFile, XFile audioFile);
  Future<void> updateSong(
    SongEntity song, {
    XFile? imageFile,
    XFile? audioFile,
  });
  Future<void> deleteSong(String id);
  Future<void> trackSongListen(SongEntity song);
}
