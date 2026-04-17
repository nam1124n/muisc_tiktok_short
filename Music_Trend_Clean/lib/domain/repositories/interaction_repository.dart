import 'package:login_flutter/domain/entities/song_entity.dart';

abstract class InteractionRepository {
  Future<List<SongEntity>> getFavorites(String userId);
  Future<void> toggleFavorite(String userId, SongEntity song, bool isFavorite);
  Future<List<SongEntity>> getRecents(String userId);
  Future<void> addRecent(String userId, SongEntity song);
}
