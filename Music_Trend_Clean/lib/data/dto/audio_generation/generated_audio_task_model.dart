import 'package:login_flutter/data/dto/audio_generation/generated_audio_model.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';

class GeneratedAudioTaskModel extends GeneratedAudioTaskEntity {
  const GeneratedAudioTaskModel({
    required super.id,
    required super.userId,
    required super.prompt,
    required super.status,
    required super.provider,
    required super.outputCount,
    required super.tracks,
    super.requestedDurationSeconds,
    super.createdAt,
    super.updatedAt,
  });

  factory GeneratedAudioTaskModel.fromJson(Map<String, dynamic> json) {
    final taskId =
        json['taskId']?.toString() ??
        json['task_id']?.toString() ??
        json['id']?.toString() ??
        '';
    final rawTracks = (json['tracks'] as List<dynamic>? ?? []);

    return GeneratedAudioTaskModel(
      id: taskId,
      userId:
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          'guest_user',
      prompt: json['prompt']?.toString() ?? '',
      requestedDurationSeconds:
          (json['requestedDurationSeconds'] as num?)?.toInt() ??
          (json['requested_duration_sec'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'processing',
      provider: json['provider']?.toString() ?? 'phoenix-backend',
      outputCount:
          (json['outputCount'] as num?)?.toInt() ??
          (json['output_count'] as num?)?.toInt() ??
          rawTracks.length,
      tracks:
          rawTracks
              .whereType<Map<String, dynamic>>()
              .map(
                (track) => GeneratedAudioModel.fromJson({
                  ...track,
                  'taskId': track['taskId'] ?? track['task_id'] ?? taskId,
                }),
              )
              .toList()
            ..sort(
              (left, right) => left.variantIndex.compareTo(right.variantIndex),
            ),
      createdAt: _readDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _readDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  @override
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
