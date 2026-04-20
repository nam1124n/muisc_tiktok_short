import 'package:login_flutter/domain/entities/song_entity.dart';

class SongModel extends SongEntity {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.audioUrl,
    required super.imageUrl,
    super.savedAt,
    super.trackInWeeklyStats = true,
  });

  factory SongModel.fromFirestore(Map<String, dynamic> map, String id) {
    return SongModel.fromEntity(SongEntity.fromJson({...map, 'id': id}));
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'artist': artist,
    'audioUrl': audioUrl,
    'imageUrl': imageUrl,
    if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
    'trackInWeeklyStats': trackInWeeklyStats,
  };

  factory SongModel.fromEntity(SongEntity entity) => SongModel(
    id: entity.id,
    title: entity.title,
    artist: entity.artist,
    audioUrl: entity.audioUrl,
    imageUrl: entity.imageUrl,
    savedAt: entity.savedAt,
    trackInWeeklyStats: entity.trackInWeeklyStats,
  );
}
