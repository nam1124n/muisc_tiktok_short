import 'package:login_flutter/domain/entities/song_entity.dart';

class SongModel extends SongEntity {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.audioUrl,
    required super.imageUrl,
    super.savedAt,
    super.audioType = SongAudioTypes.short,
    super.releaseYear,
    super.trackInWeeklyStats = true,
    super.status = SongStatuses.published,
    super.moderationReason = '',
    super.moderatedBy = '',
    super.moderatedAt,
    super.publishedAt,
    super.updatedAt,
    super.deletedAt,
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
    'audioType': audioType,
    if (releaseYear != null) 'releaseYear': releaseYear,
    'trackInWeeklyStats': trackInWeeklyStats,
    'status': status,
    'moderationReason': moderationReason,
    'moderatedBy': moderatedBy,
    'moderatedAt': moderatedAt?.toIso8601String(),
    'publishedAt': publishedAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory SongModel.fromEntity(SongEntity entity) => SongModel(
    id: entity.id,
    title: entity.title,
    artist: entity.artist,
    audioUrl: entity.audioUrl,
    imageUrl: entity.imageUrl,
    savedAt: entity.savedAt,
    audioType: entity.audioType,
    releaseYear: entity.releaseYear,
    trackInWeeklyStats: entity.trackInWeeklyStats,
    status: entity.status,
    moderationReason: entity.moderationReason,
    moderatedBy: entity.moderatedBy,
    moderatedAt: entity.moderatedAt,
    publishedAt: entity.publishedAt,
    updatedAt: entity.updatedAt,
    deletedAt: entity.deletedAt,
  );
}
