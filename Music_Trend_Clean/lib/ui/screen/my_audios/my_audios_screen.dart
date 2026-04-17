import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/my_audios/providers/my_audios_provider.dart';

class MyAudiosScreen extends ConsumerWidget {
  const MyAudiosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myAudios = ref.watch(myAudiosProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.yourAudioLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: myAudios.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE4FF),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 36,
                        color: Color(0xFF8C52FF),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.yourAudioEmptyTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Các âm thanh tạo bởi AI sẽ xuất hiện tại đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: myAudios.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final audio = myAudios[index];
                return _AudioItemCard(audio: audio);
              },
            ),
    );
  }
}

class _AudioItemCard extends ConsumerWidget {
  const _AudioItemCard({required this.audio});

  final GeneratedAudioEntity audio;

  void _playAudio(BuildContext context, WidgetRef ref) {
    final previewSong = SongEntity(
      id: audio.id,
      title: audio.title,
      artist: AppLocalizations.of(context)!.aiAudioStudio,
      audioUrl: audio.audioUrl,
      imageUrl: audio.imageUrl,
    );

    ref
        .read(audioPlayerNotifierProvider.notifier)
        .playSong(previewSong, playlist: [previewSong]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => _playAudio(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Color(0xFF8C52FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.generatedAudioMeta(
                      audio.durationSeconds,
                      audio.provider,
                    ),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF8C52FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      'Xóa âm thanh',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Bạn có chắc chắn muốn xóa "${audio.title}" khỏi danh sách?',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  ref.read(myAudiosProvider.notifier).removeAudio(audio.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
