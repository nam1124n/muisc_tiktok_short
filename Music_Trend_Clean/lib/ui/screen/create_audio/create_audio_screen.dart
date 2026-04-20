import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/config/audio_generation_config.dart';
import 'package:login_flutter/domain/entities/generated_audio_entity.dart';
import 'package:login_flutter/domain/entities/generated_audio_task_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/create_audio/providers/create_audio_provider.dart';
import 'package:login_flutter/ui/screen/create_audio/providers/create_audio_state.dart';

class CreateAudioScreen extends ConsumerStatefulWidget {
  const CreateAudioScreen({super.key});

  @override
  ConsumerState<CreateAudioScreen> createState() => _CreateAudioScreenState();
}

class _CreateAudioScreenState extends ConsumerState<CreateAudioScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final androidDeviceSetupHint = AudioGenerationConfig.androidDeviceSetupHint;

    ref.listen<CreateAudioState>(createAudioNotifierProvider, (previous, next) {
      if (previous?.status == next.status) {
        return;
      }

      if (next.status == CreateAudioStatus.error &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (next.status == CreateAudioStatus.success &&
          next.generatedTask != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.createAudioSuccessMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    final state = ref.watch(createAudioNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          l10n.createAudioTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8C52FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.promptLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _promptController,
                      maxLines: 5,
                      minLines: 4,
                      onChanged: ref
                          .read(createAudioNotifierProvider.notifier)
                          .onPromptChanged,
                      decoration: InputDecoration(
                        hintText: l10n.promptHint,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          height: 1.4,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                          borderSide: BorderSide(
                            color: Color(0xFF8C52FF),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.promptHelpText,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        l10n.createAudioApiNotice(
                          AudioGenerationConfig.baseUrl,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                    ),
                    if (androidDeviceSetupHint != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.75,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          androidDeviceSetupHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: state.status == CreateAudioStatus.loading
                            ? null
                            : () {
                                ref
                                    .read(createAudioNotifierProvider.notifier)
                                    .generateAudio(
                                      promptRequiredMessage:
                                          l10n.promptRequiredMessage,
                                      promptTooShortMessage:
                                          l10n.promptTooShortMessage,
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C52FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: state.status == CreateAudioStatus.loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          state.status == CreateAudioStatus.loading
                              ? l10n.generatingAudio
                              : l10n.createTwoVersions,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.generatedTask != null) ...[
                const SizedBox(height: 20),
                _GeneratedTaskCard(
                  generatedTask: state.generatedTask!,
                  onPreviewTrack: _previewGeneratedTrack,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _previewGeneratedTrack(GeneratedAudioEntity track) {
    final previewSong = SongEntity(
      id: track.id,
      title: track.title,
      artist: AppLocalizations.of(context)!.aiAudioStudio,
      audioUrl: track.audioUrl,
      imageUrl: track.imageUrl,
    );

    ref
        .read(audioPlayerNotifierProvider.notifier)
        .playSong(previewSong, playlist: [previewSong]);
  }
}

class _GeneratedTaskCard extends StatelessWidget {
  const _GeneratedTaskCard({
    required this.generatedTask,
    required this.onPreviewTrack,
  });

  final GeneratedAudioTaskEntity generatedTask;
  final ValueChanged<GeneratedAudioEntity> onPreviewTrack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Color(0xFF8C52FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      generatedTask.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.generatedTaskStatusMeta(
                        generatedTask.status,
                        generatedTask.tracks.length,
                        generatedTask.outputCount,
                      ),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            generatedTask.prompt,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (generatedTask.tracks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.generationQueuedHint,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: generatedTask.tracks
                  .map(
                    (track) => Padding(
                      padding: EdgeInsets.only(
                        bottom: track == generatedTask.tracks.last ? 0 : 12,
                      ),
                      child: _GeneratedTrackTile(
                        track: track,
                        onPreview: () => onPreviewTrack(track),
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

class _GeneratedTrackTile extends StatelessWidget {
  const _GeneratedTrackTile({required this.track, required this.onPreview});

  final GeneratedAudioEntity track;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final versionLabel = String.fromCharCode(65 + track.variantIndex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
          const SizedBox(height: 6),
          Text(
            track.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.generatedAudioMeta(
              track.durationSeconds,
              track.modelName.isNotEmpty ? track.modelName : track.provider,
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (track.audioUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.audioMockUrlLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              track.audioUrl,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.previewAudio),
            ),
          ),
        ],
      ),
    );
  }
}
