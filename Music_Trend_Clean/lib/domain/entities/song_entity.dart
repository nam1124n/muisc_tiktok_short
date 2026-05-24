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

class SongAudioTypes {
  static const String short = 'short';
  static const String full = 'full';

  static String normalize(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();

    return switch (normalized) {
      full => full,
      _ => short,
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
  final String audioType;
  final int? releaseYear;
  final bool trackInWeeklyStats;
  final String status;
  final String moderationReason;
  final String moderatedBy;
  final DateTime? moderatedAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? uploaderId;
  final int favoriteCount;
  final int commentCount;
  final int totalPlayCount;
  final int uniqueListenerCount;

  const SongEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.imageUrl,
    this.savedAt,
    this.audioType = SongAudioTypes.short,
    this.releaseYear,
    this.trackInWeeklyStats = true,
    this.status = SongStatuses.published,
    this.moderationReason = '',
    this.moderatedBy = '',
    this.moderatedAt,
    this.publishedAt,
    this.updatedAt,
    this.deletedAt,
    this.uploaderId,
    this.favoriteCount = 0,
    this.commentCount = 0,
    this.totalPlayCount = 0,
    this.uniqueListenerCount = 0,
  });

  factory SongEntity.fromJson(Map<String, dynamic> json) {
    return SongEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      artist: json['artist']?.toString() ?? 'Unknown',
      audioUrl: json['audioUrl']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      savedAt: _readDateTime(json['timestamp'] ?? json['savedAt']),
      audioType: SongAudioTypes.normalize(json['audioType']),
      releaseYear: _readYear(json['releaseYear'] ?? json['year']),
      trackInWeeklyStats: _readTrackInWeeklyStats(json['trackInWeeklyStats']),
      status: SongStatuses.normalize(json['status']),
      moderationReason: json['moderationReason']?.toString() ?? '',
      moderatedBy: json['moderatedBy']?.toString() ?? '',
      moderatedAt: _readDateTime(json['moderatedAt']),
      publishedAt: _readDateTime(json['publishedAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      deletedAt: _readDateTime(json['deletedAt']),
      uploaderId: json['uploaderId']?.toString(),
      favoriteCount: _readInt(json['favoriteCount']),
      commentCount: _readInt(json['commentCount']),
      totalPlayCount: _readInt(json['totalPlayCount']),
      uniqueListenerCount: _readInt(json['uniqueListenerCount']),
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
      'audioType': audioType,
      if (releaseYear != null) 'releaseYear': releaseYear,
      'trackInWeeklyStats': trackInWeeklyStats,
      'status': status,
      'moderationReason': moderationReason,
      'moderatedBy': moderatedBy,
      if (moderatedAt != null) 'moderatedAt': moderatedAt!.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (uploaderId != null) 'uploaderId': uploaderId,
      'favoriteCount': favoriteCount,
      'commentCount': commentCount,
      'totalPlayCount': totalPlayCount,
      'uniqueListenerCount': uniqueListenerCount,
    };
  }

  SongEntity copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    String? imageUrl,
    DateTime? savedAt,
    String? audioType,
    Object? releaseYear = _songEntityNoChange,
    bool? trackInWeeklyStats,
    String? status,
    String? moderationReason,
    String? moderatedBy,
    DateTime? moderatedAt,
    Object? publishedAt = _songEntityNoChange,
    DateTime? updatedAt,
    Object? deletedAt = _songEntityNoChange,
    Object? uploaderId = _songEntityNoChange,
    int? favoriteCount,
    int? commentCount,
    int? totalPlayCount,
    int? uniqueListenerCount,
  }) {
    return SongEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      savedAt: savedAt ?? this.savedAt,
      audioType: SongAudioTypes.normalize(audioType ?? this.audioType),
      releaseYear: releaseYear == _songEntityNoChange
          ? this.releaseYear
          : releaseYear as int?,
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
      uploaderId: uploaderId == _songEntityNoChange
          ? this.uploaderId
          : uploaderId as String?,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      commentCount: commentCount ?? this.commentCount,
      totalPlayCount: totalPlayCount ?? this.totalPlayCount,
      uniqueListenerCount: uniqueListenerCount ?? this.uniqueListenerCount,
    );
  }

  bool get isPublished => status == SongStatuses.published;

  bool get isPending => status == SongStatuses.pending;

  bool get isHidden => status == SongStatuses.hidden;

  bool get isArchived => status == SongStatuses.archived;

  bool get isVisibleToListeners => isPublished && !isArchived;

  bool get isShortAudio => audioType == SongAudioTypes.short;

  bool get isFullAudio => audioType == SongAudioTypes.full;

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

  static int? _readYear(Object? value) {
    return switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v),
      _ => null,
    };
  }

  static int _readInt(Object? value) {
    return switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };
  }
}

const _songEntityNoChange = Object();
