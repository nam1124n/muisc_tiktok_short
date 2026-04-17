import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/year_song_repository.dart';

class AddYearSongUseCase {
  final YearSongRepository repository;

  AddYearSongUseCase(this.repository);

  Future<void> call(SongEntity song, XFile imageFile, XFile audioFile) =>
      repository.addSong(song, imageFile, audioFile);
}
