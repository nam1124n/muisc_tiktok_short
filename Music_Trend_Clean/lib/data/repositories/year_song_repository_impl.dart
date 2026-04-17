import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/data/datasource/remote/song_remote_data_source.dart';
import 'package:login_flutter/data/datasource/remote/year_song_remote_data_source.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/repositories/year_song_repository.dart';

class YearSongRepositoryImpl implements YearSongRepository {
  final YearSongRemoteDataSource remoteDataSource;
  final SongRemoteDataSource mediaRemoteDataSource;

  YearSongRepositoryImpl(this.remoteDataSource, this.mediaRemoteDataSource);

  @override
  Stream<List<SongEntity>> getSongs() {
    return remoteDataSource.getSongsStream().map((snapshot) {
      final songs =
          snapshot.docs.map((doc) => _mapSong(doc.data(), doc.id)).toList()
            ..sort((a, b) {
              final yearCompare = (b.savedAt?.year ?? 0).compareTo(
                a.savedAt?.year ?? 0,
              );
              if (yearCompare != 0) {
                return yearCompare;
              }

              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            });

      return songs;
    });
  }

  @override
  Future<void> addSong(
    SongEntity song,
    XFile imageFile,
    XFile audioFile,
  ) async {
    final results = await Future.wait([
      mediaRemoteDataSource.uploadImage(imageFile),
      mediaRemoteDataSource.uploadAudio(audioFile),
    ]);

    await remoteDataSource.addSong(
      _toMap(song, imageUrl: results[0], audioUrl: results[1]),
    );
  }

  @override
  Future<void> updateSong(
    SongEntity song, {
    XFile? imageFile,
    XFile? audioFile,
  }) async {
    var imageUrl = song.imageUrl;
    var audioUrl = song.audioUrl;

    if (imageFile != null) {
      imageUrl = await mediaRemoteDataSource.uploadImage(imageFile);
    }

    if (audioFile != null) {
      audioUrl = await mediaRemoteDataSource.uploadAudio(audioFile);
    }

    await remoteDataSource.updateSong(
      song.id,
      _toMap(song, imageUrl: imageUrl, audioUrl: audioUrl),
    );
  }

  @override
  Future<void> deleteSong(String id) async {
    await remoteDataSource.deleteSong(id);
  }

  SongEntity _mapSong(Map<String, dynamic> map, String id) {
    final year = _readYear(map['year']);
    final savedAt =
        map['savedAt']?.toString() ??
        (year != null ? DateTime(year, 1, 1).toIso8601String() : null);

    return SongEntity.fromJson({
      ...map,
      'id': id,
      'savedAt': savedAt,
      'trackInWeeklyStats': false,
    });
  }

  Map<String, dynamic> _toMap(
    SongEntity song, {
    required String imageUrl,
    required String audioUrl,
  }) {
    final savedAt = song.savedAt ?? DateTime.now();

    return {
      'title': song.title,
      'artist': song.artist,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'savedAt': savedAt.toIso8601String(),
      'year': savedAt.year,
      'trackInWeeklyStats': false,
    };
  }

  int? _readYear(Object? value) {
    return switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };
  }
}
