import 'package:login_flutter/domain/entities/generated_audio_entity.dart';

class GeneratedAudioModel extends GeneratedAudioEntity {
  const GeneratedAudioModel({
    required super.id,
    required super.taskId,
    required super.variantIndex,
    required super.title,
    required super.prompt,
    required super.audioUrl,
    required super.streamAudioUrl,
    required super.imageUrl,
    required super.durationSeconds,
    required super.provider,
    required super.modelName,
    super.tags = const [],
    super.createdAt,
  });

  factory GeneratedAudioModel.fromJson(Map<String, dynamic> json) {
    return GeneratedAudioModel(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? json['task_id']?.toString() ?? '',
      variantIndex:
          (json['variantIndex'] as num?)?.toInt() ??
          (json['variant_index'] as num?)?.toInt() ??
          0,
      title: json['title']?.toString() ?? 'AI Audio',
      prompt: json['prompt']?.toString() ?? '',
      audioUrl:
          json['audioUrl']?.toString() ?? json['audio_url']?.toString() ?? '',
      streamAudioUrl:
          json['streamAudioUrl']?.toString() ??
          json['stream_audio_url']?.toString() ??
          json['audioUrl']?.toString() ??
          json['audio_url']?.toString() ??
          '',
      imageUrl:
          json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      durationSeconds:
          (json['durationSeconds'] as num?)?.toInt() ??
          (json['duration_seconds'] as num?)?.toInt() ??
          (json['duration_sec'] as num?)?.toInt() ??
          0,
      provider: json['provider']?.toString() ?? 'phoenix-backend',
      modelName:
          json['modelName']?.toString() ?? json['model_name']?.toString() ?? '',
      tags: _readStringList(json['tags']),
      createdAt: _readDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'variantIndex': variantIndex,
      'title': title,
      'prompt': prompt,
      'audioUrl': audioUrl,
      'streamAudioUrl': streamAudioUrl,
      'imageUrl': imageUrl,
      'durationSeconds': durationSeconds,
      'provider': provider,
      'modelName': modelName,
      'tags': tags,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  static List<String> _readStringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split(RegExp(r'[,;\n]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
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
