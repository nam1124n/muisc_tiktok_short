import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/my_audios/providers/my_audios_provider.dart';

class MyAudiosScreen extends ConsumerWidget {
  const MyAudiosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myAudiosState = ref.watch(myAudiosProvider);
    final tasks = myAudiosState.tasks;

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
      body: RefreshIndicator(
        onRefresh: () => ref.read(myAudiosProvider.notifier).reload(),
        child: Builder(
          builder: (context) {
            if (myAudiosState.isLoadingInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (myAudiosState.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 44,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              myAudiosState.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                ref.read(myAudiosProvider.notifier).reload();
                              },
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (myAudiosState.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                            Text(
                              l10n.yourAudioEmptySubtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                if (myAudiosState.isSyncingRemote)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _AudioTaskCard(task: task);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AudioTaskCard extends ConsumerWidget {
  const _AudioTaskCard({required this.task});

  final GeneratedAudioTaskEntity task;

  void _playAudio(
    BuildContext context,
    WidgetRef ref,
    GeneratedAudioEntity audio,
  ) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      task.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.generatedTaskStatusMeta(
                        task.status,
                        task.tracks.length,
                        task.outputCount,
                      ),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                      title: Text(
                        l10n.deleteGeneratedTaskTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        l10n.deleteGeneratedTaskMessage(task.displayTitle),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            l10n.deleteLabel,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref
                        .read(myAudiosProvider.notifier)
                        .removeTask(task.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.prompt,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: task.tracks
                .map(
                  (audio) => Padding(
                    padding: EdgeInsets.only(
                      bottom: audio == task.tracks.last ? 0 : 10,
                    ),
                    child: _TaskTrackRow(
                      audio: audio,
                      onPlay: () => _playAudio(context, ref, audio),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TaskTrackRow extends StatelessWidget {
  const _TaskTrackRow({required this.audio, required this.onPlay});

  final GeneratedAudioEntity audio;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final versionLabel = String.fromCharCode(65 + audio.variantIndex);

    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF8C52FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.generatedVersionLabel(versionLabel),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8C52FF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    audio.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.generatedAudioMeta(
                      audio.durationSeconds,
                      audio.modelName.isNotEmpty
                          ? audio.modelName
                          : audio.provider,
                    ),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
