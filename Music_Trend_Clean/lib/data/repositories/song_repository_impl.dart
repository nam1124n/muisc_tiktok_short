import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/song_page_entity.dart';
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
      return snapshot.docs
          .map((doc) {
            return SongModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          })
          .where((song) => song.isVisibleToListeners)
          .toList();
    });
  }

  @override
  Stream<List<SongEntity>> getAdminSongs() {
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
  Future<SongPageEntity> fetchSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) async {
    final page = await remoteDataSource.fetchSongsPage(
      limit: limit,
      startAfter: startAfter,
    );

    return SongPageEntity(
      songs: page.songs.where((song) => song.isVisibleToListeners).toList(),
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  @override
  Future<SongPageEntity> fetchFeedSongsPage({
    int limit = 20,
    SongPageCursor? startAfter,
  }) async {
    final page = await remoteDataSource.fetchFeedSongsPage(
      limit: limit,
      startAfter: startAfter,
    );
    final visibleSongs =
        page.songs.where((song) => song.isVisibleToListeners).toList()
          ..sort(_compareFeedSongs);

    return SongPageEntity(
      songs: visibleSongs,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  @override
  Stream<List<TrendingSongEntity>> getWeeklyTrendingSongs({int limit = 4}) {
    return remoteDataSource.getWeeklyTrendingSongsStream().map((snapshot) {
      final rankedSongs =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                final song = SongModel.fromFirestore(data, doc.id);
                if (!song.isVisibleToListeners) {
                  return null;
                }

                return TrendingSongEntity(
                  song: song,
                  uniqueUserCount:
                      (data['uniqueUserCount'] as num?)?.toInt() ?? 0,
                  totalPlayCount:
                      (data['totalPlayCount'] as num?)?.toInt() ?? 0,
                );
              })
              .whereType<TrendingSongEntity>()
              .toList()
            ..sort((a, b) {
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
    await remoteDataSource.ensureAdminAccess();
    final results = await Future.wait([
      remoteDataSource.uploadImage(imageFile),
      remoteDataSource.uploadAudio(audioFile),
    ]);
    final imageUrl = results[0];
    final audioUrl = results[1];

    final model = SongModel.fromEntity(_withPublishDates(song));
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
    await remoteDataSource.ensureAdminAccess();
    var imageUrl = song.imageUrl;
    var audioUrl = song.audioUrl;

    if (imageFile != null) {
      imageUrl = await remoteDataSource.uploadImage(imageFile);
    }

    if (audioFile != null) {
      audioUrl = await remoteDataSource.uploadAudio(audioFile);
    }

    final model = SongModel.fromEntity(_withPublishDates(song));
    await remoteDataSource.updateSong(song.id, {
      ...model.toMap(),
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
    });
  }

  @override
  Future<void> deleteSong(String id) async {
    await remoteDataSource.ensureAdminAccess();
    await remoteDataSource.deleteSong(id);
  }

  @override
  Future<void> trackSongListen(SongEntity song) async {
    final model = SongModel.fromEntity(song);
    await remoteDataSource.trackSongListen({...model.toMap(), 'id': song.id});
  }

  int _compareFeedSongs(SongEntity left, SongEntity right) {
    final rightTime = _feedSortTime(right);
    final leftTime = _feedSortTime(left);
    final timeCompare = rightTime.compareTo(leftTime);
    if (timeCompare != 0) {
      return timeCompare;
    }

    return right.title.compareTo(left.title);
  }

  int _feedSortTime(SongEntity song) {
    return (song.publishedAt ?? song.updatedAt ?? song.savedAt)
            ?.millisecondsSinceEpoch ??
        0;
  }

  SongEntity _withPublishDates(SongEntity song) {
    final now = DateTime.now();
    return song.copyWith(
      publishedAt: song.isPublished ? song.publishedAt ?? now : song.publishedAt,
      updatedAt: now,
    );
  }
}
