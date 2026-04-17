import 'package:login_flutter/domain/entities/song_entity.dart';
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
  Future<List<SongEntity>> getRecents(String userId) async {
    final data = await remoteDataSource.getRecents(userId);
    return data.map((json) => SongEntity.fromJson(json)).toList();
  }

  @override
  Future<void> addRecent(String userId, SongEntity song) async {
    await remoteDataSource.addRecent(userId, song.toJson());
  }
}
