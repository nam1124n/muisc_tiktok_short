class GeneratedAudioEntity {
  final String id;
  final String title;
  final String prompt;
  final String audioUrl;
  final String imageUrl;
  final int durationSeconds;
  final String provider;

  const GeneratedAudioEntity({
    required this.id,
    required this.title,
    required this.prompt,
    required this.audioUrl,
    required this.imageUrl,
    required this.durationSeconds,
    required this.provider,
  });

  factory GeneratedAudioEntity.fromJson(Map<String, dynamic> json) {
    return GeneratedAudioEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      prompt: json['prompt']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      durationSeconds: json['durationSeconds'] is int
          ? json['durationSeconds']
          : int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0,
      provider: json['provider']?.toString() ?? 'Suno',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'prompt': prompt,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'durationSeconds': durationSeconds,
      'provider': provider,
    };
  }
}
