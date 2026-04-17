import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/year_song_repository.dart';

class UpdateYearSongUseCase {
  final YearSongRepository repository;

  UpdateYearSongUseCase(this.repository);

  Future<void> call(SongEntity song, {XFile? imageFile, XFile? audioFile}) =>
      repository.updateSong(song, imageFile: imageFile, audioFile: audioFile);
}
