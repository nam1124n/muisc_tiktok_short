import 'package:equatable/equatable.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';

class ListeningHistoryEntryEntity extends Equatable {
  const ListeningHistoryEntryEntity({
    required this.song,
    this.lastPlayedAt,
    this.playCount = 0,
    this.completedCount = 0,
    this.lastPosition = Duration.zero,
    this.duration = Duration.zero,
  });

  final SongEntity song;
  final DateTime? lastPlayedAt;
  final int playCount;
  final int completedCount;
  final Duration lastPosition;
  final Duration duration;

  double get progress {
    if (duration == Duration.zero) {
      return 0;
    }

    final clampedMilliseconds = lastPosition.inMilliseconds.clamp(
      0,
      duration.inMilliseconds,
    );
    return clampedMilliseconds / duration.inMilliseconds;
  }

  bool get canContinueListening {
    if (duration == Duration.zero) {
      return false;
    }

    return lastPosition.inSeconds >= 15 && progress < 0.9;
  }

  factory ListeningHistoryEntryEntity.fromJson(Map<String, dynamic> json) {
    final song = SongEntity.fromJson(json);

    return ListeningHistoryEntryEntity(
      song: song,
      lastPlayedAt: song.savedAt,
      playCount: _readInt(json['playCount']),
      completedCount: _readInt(json['completedCount']),
      lastPosition: Duration(seconds: _readInt(json['lastPositionSeconds'])),
      duration: Duration(seconds: _readInt(json['durationSeconds'])),
    );
  }

  ListeningHistoryEntryEntity copyWith({
    SongEntity? song,
    DateTime? lastPlayedAt,
    int? playCount,
    int? completedCount,
    Duration? lastPosition,
    Duration? duration,
    bool clearLastPosition = false,
  }) {
    return ListeningHistoryEntryEntity(
      song: song ?? this.song,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      playCount: playCount ?? this.playCount,
      completedCount: completedCount ?? this.completedCount,
      lastPosition: clearLastPosition
          ? Duration.zero
          : lastPosition ?? this.lastPosition,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toProgressJson({
    required int positionSeconds,
    required int durationSeconds,
    required bool markCompleted,
  }) {
    return {
      ...song.toJson(),
      'playCount': playCount,
      'completedCount': completedCount,
      'lastPositionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
      'timestamp': lastPlayedAt?.toIso8601String(),
      'markCompleted': markCompleted,
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

  @override
  List<Object?> get props => [
    song,
    lastPlayedAt,
    playCount,
    completedCount,
    lastPosition,
    duration,
  ];
}
