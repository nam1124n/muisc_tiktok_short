import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/domain/repositories/song_repository.dart';
import 'package:login_flutter/data/datasource/remote/song_remote_data_source.dart';
import 'package:login_flutter/data/dto/admin/song_model.dart';

class SongRepositoryImpl implements SongRepository {
  final SongRemoteDataSource remoteDataSource;
  SongRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<SongEntity>> getSongs() {
    return remoteDataSource.getSongsStream().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SongModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  @override
  Stream<List<TrendingSongEntity>> getWeeklyTrendingSongs({int limit = 4}) {
    return remoteDataSource.getWeeklyTrendingSongsStream().map((snapshot) {
      final rankedSongs =
          snapshot.docs.map((doc) {
            final data = doc.data();

            return TrendingSongEntity(
              song: SongModel.fromFirestore(data, doc.id),
              uniqueUserCount: (data['uniqueUserCount'] as num?)?.toInt() ?? 0,
              totalPlayCount: (data['totalPlayCount'] as num?)?.toInt() ?? 0,
            );
          }).toList()..sort((a, b) {
            final uniqueCompare = b.uniqueUserCount.compareTo(
              a.uniqueUserCount,
            );
            if (uniqueCompare != 0) {
              return uniqueCompare;
            }

            return b.totalPlayCount.compareTo(a.totalPlayCount);
          });

      return rankedSongs.take(limit).toList();
    });
  }

  @override
  Future<void> addSong(
    SongEntity song,
    XFile imageFile,
    XFile audioFile,
  ) async {
    final results = await Future.wait([
      remoteDataSource.uploadImage(imageFile),
      remoteDataSource.uploadAudio(audioFile),
    ]);
    final imageUrl = results[0];
    final audioUrl = results[1];

    final model = SongModel.fromEntity(song);
    await remoteDataSource.addSong({
      ...model.toMap(),
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    });
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
      imageUrl = await remoteDataSource.uploadImage(imageFile);
    }

    if (audioFile != null) {
      audioUrl = await remoteDataSource.uploadAudio(audioFile);
    }

    final model = SongModel.fromEntity(song);
    await remoteDataSource.updateSong(song.id, {
      ...model.toMap(),
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    });
  }

  @override
  Future<void> deleteSong(String id) async {
    await remoteDataSource.deleteSong(id);
  }

  @override
  Future<void> trackSongListen(SongEntity song) async {
    final model = SongModel.fromEntity(song);
    await remoteDataSource.trackSongListen({...model.toMap(), 'id': song.id});
  }
}
