import 'package:login_flutter/domain/entities/listening_history_entry_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

abstract class InteractionRepository {
  Future<List<SongEntity>> getFavorites(String userId);
  Future<void> toggleFavorite(String userId, SongEntity song, bool isFavorite);
  Future<void> clearFavorites(String userId, List<String> songIds);
  Future<List<ListeningHistoryEntryEntity>> getHistoryEntries(String userId);
  Future<void> addRecent(String userId, SongEntity song);
  Future<void> updateRecentProgress(
    String userId,
    SongEntity song, {
    required Duration position,
    required Duration duration,
    bool markCompleted = false,
  });
  Future<void> clearRecents(String userId, List<String> songIds);
}
