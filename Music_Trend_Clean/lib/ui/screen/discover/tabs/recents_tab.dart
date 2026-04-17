import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';

class RecentsTab extends ConsumerWidget {
  const RecentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSongs = ref.watch(recentNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    if (recentSongs.isEmpty) {
      return Center(
        child: Text(
          l10n.recentSongsEmpty,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: recentSongs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final song = recentSongs[index];
        return _buildSongItem(context, song, recentSongs);
      },
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    SongEntity song,
    List<SongEntity> playlist,
  ) {
    final Color cardColor = const Color(0xFF0EA5E9);

    return Consumer(
      builder: (context, ref, _) {
        final favoriteSongs = ref.watch(favoriteNotifierProvider);
        final playerState = ref.watch(audioPlayerNotifierProvider);
        final isFavorite = favoriteSongs.any((s) => s.id == song.id);
        final isPlayingThisSong =
            playerState.currentSong?.id == song.id && playerState.isPlaying;
        final isLoadingThisSong =
            playerState.currentSong?.id == song.id && playerState.isLoading;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: song.imageUrl.isNotEmpty
                    ? Image.network(
                        song.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 28,
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          size: 14,
                          color: Color(0xFF8C52FF),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            song.artist,
                            style: const TextStyle(
                              color: Color(0xFF8C52FF),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ref
                      .read(favoriteNotifierProvider.notifier)
                      .toggleFavorite(song);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? const Color(0xFFF43F5E)
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (isPlayingThisSong) {
                    ref.read(audioPlayerNotifierProvider.notifier).pause();
                  } else if (playerState.currentSong?.id == song.id) {
                    ref.read(audioPlayerNotifierProvider.notifier).resume();
                  } else {
                    ref
                        .read(audioPlayerNotifierProvider.notifier)
                        .playSong(song, playlist: playlist);
                    ref.read(recentNotifierProvider.notifier).addRecent(song);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: isLoadingThisSong
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF8C52FF),
                          ),
                        )
                      : Icon(
                          isPlayingThisSong
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          color: isPlayingThisSong
                              ? const Color(0xFF8C52FF)
                              : Colors.grey.shade400,
                          size: 28,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
