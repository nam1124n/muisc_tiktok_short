import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';

class UpdateSongUseCase {
  final SongRepository repository;

  UpdateSongUseCase(this.repository);

  Future<void> call(SongEntity song, {XFile? imageFile, XFile? audioFile}) =>
      repository.updateSong(song, imageFile: imageFile, audioFile: audioFile);
}
