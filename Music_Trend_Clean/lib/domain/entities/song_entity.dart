class SongEntity {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String imageUrl;
  final DateTime? savedAt;
  final bool trackInWeeklyStats;

  const SongEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.imageUrl,
    this.savedAt,
    this.trackInWeeklyStats = true,
  });

  factory SongEntity.fromJson(Map<String, dynamic> json) {
    return SongEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      artist: json['artist']?.toString() ?? 'Unknown',
      audioUrl: json['audioUrl']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      savedAt: _readDateTime(json['timestamp'] ?? json['savedAt']),
      trackInWeeklyStats: _readTrackInWeeklyStats(json['trackInWeeklyStats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      if (savedAt != null) 'timestamp': savedAt!.toIso8601String(),
      'trackInWeeklyStats': trackInWeeklyStats,
    };
  }

  static bool _readTrackInWeeklyStats(Object? value) {
    return switch (value) {
      bool v => v,
      String v => v.toLowerCase() != 'false',
      num v => v != 0,
      _ => true,
    };
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      final converted = (value as dynamic).toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Ignore unsupported timestamp formats.
    }

    return null;
  }
}
