class GeneratedAudioEntity {
  final String id;
  final String taskId;
  final int variantIndex;
  final String title;
  final String prompt;
  final String audioUrl;
  final String streamAudioUrl;
  final String imageUrl;
  final int durationSeconds;
  final String provider;
  final String modelName;
  final List<String> tags;
  final DateTime? createdAt;

  const GeneratedAudioEntity({
    required this.id,
    required this.taskId,
    required this.variantIndex,
    required this.title,
    required this.prompt,
    required this.audioUrl,
    required this.streamAudioUrl,
    required this.imageUrl,
    required this.durationSeconds,
    required this.provider,
    required this.modelName,
    this.tags = const [],
    this.createdAt,
  });

  factory GeneratedAudioEntity.fromJson(Map<String, dynamic> json) {
    return GeneratedAudioEntity(
      id: json['id']?.toString() ?? '',
      taskId:
          json['taskId']?.toString() ??
          json['task_id']?.toString() ??
          json['generationId']?.toString() ??
          '',
      variantIndex: json['variantIndex'] is int
          ? json['variantIndex']
          : int.tryParse(json['variantIndex']?.toString() ?? '') ??
                (json['variant_index'] is int
                    ? json['variant_index']
                    : int.tryParse(json['variant_index']?.toString() ?? '') ??
                          0),
      title: json['title']?.toString() ?? 'Unknown',
      prompt: json['prompt']?.toString() ?? '',
      audioUrl:
          json['audioUrl']?.toString() ?? json['audio_url']?.toString() ?? '',
      streamAudioUrl:
          json['streamAudioUrl']?.toString() ??
          json['stream_audio_url']?.toString() ??
          json['audioUrl']?.toString() ??
          '',
      imageUrl:
          json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      durationSeconds: json['durationSeconds'] is int
          ? json['durationSeconds']
          : int.tryParse(json['durationSeconds']?.toString() ?? '') ??
                (json['duration_sec'] is int
                    ? json['duration_sec']
                    : int.tryParse(json['duration_sec']?.toString() ?? '') ??
                          0),
      provider: json['provider']?.toString() ?? 'Suno',
      modelName:
          json['modelName']?.toString() ?? json['model_name']?.toString() ?? '',
      tags: _readStringList(json['tags']),
      createdAt: _readDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

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
