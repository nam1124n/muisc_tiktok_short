import 'package:login_flutter/domain/entities/generated_audio_entity.dart';

class GeneratedAudioTaskEntity {
  final String id;
  final String userId;
  final String prompt;
  final int? requestedDurationSeconds;
  final String status;
  final String provider;
  final int outputCount;
  final List<GeneratedAudioEntity> tracks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GeneratedAudioTaskEntity({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.status,
    required this.provider,
    required this.outputCount,
    required this.tracks,
    this.requestedDurationSeconds,
    this.createdAt,
    this.updatedAt,
  });

  GeneratedAudioEntity? get primaryTrack =>
      tracks.isEmpty ? null : tracks.first;

  String get displayTitle => primaryTrack?.title ?? 'AI Audio Generation';

  factory GeneratedAudioTaskEntity.fromJson(Map<String, dynamic> json) {
    final taskId =
        json['taskId']?.toString() ??
        json['task_id']?.toString() ??
        json['id']?.toString() ??
        '';
    final tracks =
        (json['tracks'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(
              (track) => GeneratedAudioEntity.fromJson({
                ...track,
                'taskId': track['taskId'] ?? track['task_id'] ?? taskId,
              }),
            )
            .toList()
          ..sort(
            (left, right) => left.variantIndex.compareTo(right.variantIndex),
          );

    return GeneratedAudioTaskEntity(
      id: taskId,
      userId:
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          'guest_user',
      prompt: json['prompt']?.toString() ?? '',
      requestedDurationSeconds: json['requestedDurationSeconds'] is int
          ? json['requestedDurationSeconds']
          : int.tryParse(json['requestedDurationSeconds']?.toString() ?? '') ??
                (json['requested_duration_sec'] is int
                    ? json['requested_duration_sec']
                    : int.tryParse(
                        json['requested_duration_sec']?.toString() ?? '',
                      )),
      status: json['status']?.toString() ?? 'processing',
      provider: json['provider']?.toString() ?? 'suno',
      outputCount: json['outputCount'] is int
          ? json['outputCount']
          : int.tryParse(json['outputCount']?.toString() ?? '') ??
                (json['output_count'] is int
                    ? json['output_count']
                    : int.tryParse(json['output_count']?.toString() ?? '') ??
                          tracks.length),
      tracks: tracks,
      createdAt: _readDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _readDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': id,
      'userId': userId,
      'prompt': prompt,
      if (requestedDurationSeconds != null)
        'requestedDurationSeconds': requestedDurationSeconds,
      'status': status,
      'provider': provider,
      'outputCount': outputCount,
      'tracks': tracks.map((track) => track.toJson()).toList(),
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
    } catch (_) {}

    return null;
  }
}
