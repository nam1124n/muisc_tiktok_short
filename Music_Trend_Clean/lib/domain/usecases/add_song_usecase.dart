import 'package:image_picker/image_picker.dart';

import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';

class AddSongUseCase {
  final SongRepository repository;
  AddSongUseCase(this.repository);

  Future<void> call(SongEntity song, XFile imageFile, XFile audioFile) =>
      repository.addSong(song, imageFile, audioFile);
}
