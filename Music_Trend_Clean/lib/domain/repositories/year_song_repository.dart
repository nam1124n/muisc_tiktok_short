import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

abstract class YearSongRepository {
  Stream<List<SongEntity>> getSongs();
  Future<void> addSong(SongEntity song, XFile imageFile, XFile audioFile);
  Future<void> updateSong(
    SongEntity song, {
    XFile? imageFile,
    XFile? audioFile,
  });
  Future<void> deleteSong(String id);
}
