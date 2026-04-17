class AudioEntity {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String duration;
  final bool isMusicSub;
  final String? desc;

  AudioEntity({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.duration,
    this.isMusicSub = false,
    this.desc,
  });
}
