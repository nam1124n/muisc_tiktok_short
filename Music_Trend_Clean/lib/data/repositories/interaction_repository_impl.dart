import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/listening_history_entry_entity.dart';
import 'package:login_flutter/domain/repositories/interaction_repository.dart';
import 'package:login_flutter/data/datasource/remote/interaction_remote_data_source.dart';

class InteractionRepositoryImpl implements InteractionRepository {
  final InteractionRemoteDataSource remoteDataSource;

  InteractionRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<SongEntity>> getFavorites(String userId) async {
    final data = await remoteDataSource.getFavorites(userId);
    return data.map((json) => SongEntity.fromJson(json)).toList();
  }

  @override
  Future<void> toggleFavorite(
    String userId,
    SongEntity song,
    bool isFavorite,
  ) async {
    await remoteDataSource.toggleFavorite(userId, song.toJson(), isFavorite);
  }

  @override
  Future<void> clearFavorites(String userId, List<String> songIds) async {
    await remoteDataSource.clearFavorites(userId, songIds);
  }

  @override
  Future<List<ListeningHistoryEntryEntity>> getHistoryEntries(
    String userId,
  ) async {
    final data = await remoteDataSource.getRecents(userId);
    return data
        .map((json) => ListeningHistoryEntryEntity.fromJson(json))
        .toList();
  }

  @override
  Future<void> addRecent(String userId, SongEntity song) async {
    await remoteDataSource.addRecent(userId, song.toJson());
  }

  @override
  Future<void> updateRecentProgress(
    String userId,
    SongEntity song, {
    required Duration position,
    required Duration duration,
    bool markCompleted = false,
  }) async {
    await remoteDataSource.updateRecentProgress(
      userId,
      song.toJson(),
      positionSeconds: position.inSeconds,
      durationSeconds: duration.inSeconds,
      markCompleted: markCompleted,
    );
  }

  @override
  Future<void> clearRecents(String userId, List<String> songIds) async {
    await remoteDataSource.clearRecents(userId, songIds);
  }
}
