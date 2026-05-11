class SongStatuses {
  static const String pending = 'pending';
  static const String published = 'published';
  static const String hidden = 'hidden';
  static const String archived = 'archived';

  static String normalize(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();

    return switch (normalized) {
      pending => pending,
      hidden => hidden,
      archived => archived,
      _ => published,
    };
  }
}

class SongEntity {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String imageUrl;
  final DateTime? savedAt;
  final bool trackInWeeklyStats;
  final String status;
  final String moderationReason;
  final String moderatedBy;
  final DateTime? moderatedAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const SongEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.imageUrl,
    this.savedAt,
    this.trackInWeeklyStats = true,
    this.status = SongStatuses.published,
    this.moderationReason = '',
    this.moderatedBy = '',
    this.moderatedAt,
    this.publishedAt,
    this.updatedAt,
    this.deletedAt,
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
      status: SongStatuses.normalize(json['status']),
      moderationReason: json['moderationReason']?.toString() ?? '',
      moderatedBy: json['moderatedBy']?.toString() ?? '',
      moderatedAt: _readDateTime(json['moderatedAt']),
      publishedAt: _readDateTime(json['publishedAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      deletedAt: _readDateTime(json['deletedAt']),
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
      'status': status,
      'moderationReason': moderationReason,
      'moderatedBy': moderatedBy,
      if (moderatedAt != null) 'moderatedAt': moderatedAt!.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    };
  }

  SongEntity copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    String? imageUrl,
    DateTime? savedAt,
    bool? trackInWeeklyStats,
    String? status,
    String? moderationReason,
    String? moderatedBy,
    DateTime? moderatedAt,
    Object? publishedAt = _songEntityNoChange,
    DateTime? updatedAt,
    Object? deletedAt = _songEntityNoChange,
  }) {
    return SongEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      savedAt: savedAt ?? this.savedAt,
      trackInWeeklyStats: trackInWeeklyStats ?? this.trackInWeeklyStats,
      status: SongStatuses.normalize(status ?? this.status),
      moderationReason: moderationReason ?? this.moderationReason,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      publishedAt: publishedAt == _songEntityNoChange
          ? this.publishedAt
          : publishedAt as DateTime?,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt == _songEntityNoChange
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }

  bool get isPublished => status == SongStatuses.published;

  bool get isPending => status == SongStatuses.pending;

  bool get isHidden => status == SongStatuses.hidden;

  bool get isArchived => status == SongStatuses.archived;

  bool get isVisibleToListeners => isPublished && !isArchived;

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

const _songEntityNoChange = Object();
