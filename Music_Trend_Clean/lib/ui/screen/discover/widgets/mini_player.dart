import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerNotifierProvider);

    if (state.currentSong == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF8C52FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: state.currentSong!.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      state.currentSong!.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.currentSong!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  state.currentSong!.artist,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.skip_previous,
                  color: state.currentIndex > 0 || state.position.inSeconds > 3
                      ? Colors.white
                      : Colors.white38,
                  size: 24,
                ),
                onPressed: () {
                  ref.read(audioPlayerNotifierProvider.notifier).previous();
                },
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  if (state.isPlaying) {
                    ref.read(audioPlayerNotifierProvider.notifier).pause();
                  } else {
                    ref.read(audioPlayerNotifierProvider.notifier).resume();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.skip_next,
                  color: state.currentIndex < state.playlist.length - 1
                      ? Colors.white
                      : Colors.white38,
                  size: 24,
                ),
                onPressed: () {
                  ref.read(audioPlayerNotifierProvider.notifier).next();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}
