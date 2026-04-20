import 'package:login_flutter/domain/entities/playlist_entity.dart';

class PlaylistModel extends PlaylistEntity {
  const PlaylistModel({
    required super.id,
    required super.name,
    required super.coverUrl,
    super.songIds,
    super.createdAt,
    super.updatedAt,
  });

  factory PlaylistModel.fromFirestore(Map<String, dynamic> json, String id) {
    return PlaylistModel(
      id: id,
      name: json['name']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      songIds: (json['songIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  factory PlaylistModel.fromEntity(PlaylistEntity entity) {
    return PlaylistModel(
      id: entity.id,
      name: entity.name,
      coverUrl: entity.coverUrl,
      songIds: entity.songIds,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverUrl': coverUrl,
      'songIds': songIds,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    try {
      final converted = (value as dynamic).toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Ignore unsupported timestamp values.
    }

    return null;
  }
}
