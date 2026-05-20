import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/audio/widgets/audio_queue_sheet.dart';
import 'package:login_flutter/ui/screen/audio/widgets/full_player_sheet.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(miniPlayerStateProvider);
    final notifier = ref.read(audioPlayerNotifierProvider.notifier);

    final currentSong = state.currentSong;
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final isFavorite = ref.watch(isFavoriteSongProvider(currentSong.id));
    final isFavoriteBusy = ref.watch(
      isFavoriteSongBusyProvider(currentSong.id),
    );
    final progress = ref.watch(
      audioPlayerNotifierProvider.select(
        (playerState) =>
            _progressValue(playerState.position, playerState.duration),
      ),
    );

    return GestureDetector(
      onTap: () => showFullPlayerSheet(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3B3B3D),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (state.isPlaying) {
                  notifier.pause();
                } else {
                  notifier.resume();
                }
              },
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.24),
                        color: const Color(0xFFFF6A00),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                        image: currentSong.imageUrl.isEmpty
                            ? null
                            : DecorationImage(
                                image: NetworkImage(currentSong.imageUrl),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: currentSong.imageUrl.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.music_note,
                                color: Colors.white54,
                                size: 20,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: state.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF8C52FF),
                              ),
                            )
                          : Icon(
                              state.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: const Color(0xFF111111),
                              size: 24,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentSong.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentSong.artist,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              icon: Icon(
                Icons.queue_music_rounded,
                color: Colors.white,
                size: 23,
              ),
              onPressed: () => showAudioQueueSheet(context),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              icon: isFavoriteBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 25,
                    ),
              onPressed: isFavoriteBusy
                  ? null
                  : () {
                      ref
                          .read(favoriteNotifierProvider.notifier)
                          .toggleFavorite(currentSong);
                    },
            ),
          ],
        ),
      ),
    );
  }

  static double _progressValue(Duration position, Duration duration) {
    if (duration <= Duration.zero) {
      return 0;
    }

    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}
