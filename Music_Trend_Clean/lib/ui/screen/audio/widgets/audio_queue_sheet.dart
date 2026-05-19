import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';

Future<void> showAudioQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AudioQueueSheet(),
  );
}

class AudioQueueSheet extends ConsumerWidget {
  const AudioQueueSheet({super.key});

  static const Color _surface = Color(0xFF111112);
  static const Color _muted = Color(0xFF8E8E93);
  static const Color _danger = Color(0xFFFF3B45);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerNotifierProvider);
    final playerNotifier = ref.read(audioPlayerNotifierProvider.notifier);
    final recentSongs = ref.watch(recentSongsProvider);
    final currentSong = playerState.currentSong;
    final nextStartIndex = playerState.currentIndex + 1;
    final nextSongs = nextStartIndex <= 0
        ? const <SongEntity>[]
        : playerState.playlist.skip(nextStartIndex).toList(growable: false);
    final recentlyPlayed = [
      for (final song in recentSongs)
        if (song.id != currentSong?.id) song,
    ].take(8).toList(growable: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: _surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _QueueHeader(
                  isShuffleEnabled: playerState.isShuffleEnabled,
                  isRepeatEnabled: playerState.isRepeatEnabled,
                  onClose: () => Navigator.of(context).pop(),
                  onShuffle: playerNotifier.toggleShuffle,
                  onRepeat: playerNotifier.toggleRepeat,
                ),
              ),
              if (recentlyPlayed.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverList.builder(
                  itemCount: recentlyPlayed.length,
                  itemBuilder: (context, index) {
                    final song = recentlyPlayed[index];
                    return _QueueSongTile(
                      song: song,
                      onTap: () => playerNotifier.playSong(
                        song,
                        playlist: playerState.playlist.isEmpty
                            ? [song]
                            : playerState.playlist,
                      ),
                    );
                  },
                ),
              ],
              if (currentSong != null) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                const SliverToBoxAdapter(
                  child: _SectionTitle('Currently playing'),
                ),
                SliverToBoxAdapter(
                  child: _QueueSongTile(
                    song: currentSong,
                    isCurrent: true,
                    onTap: () {},
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              const SliverToBoxAdapter(child: _SectionTitle('Playing next')),
              if (nextSongs.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Text(
                      'No songs queued.',
                      style: TextStyle(color: _muted, fontSize: 16),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverReorderableList(
                    itemCount: nextSongs.length,
                    onReorder: (oldIndex, newIndex) {
                      playerNotifier.moveQueueItem(
                        nextStartIndex + oldIndex,
                        nextStartIndex + newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final song = nextSongs[index];
                      final playlistIndex = nextStartIndex + index;
                      return _QueueSongTile(
                        key: ValueKey('next-${song.id}-$playlistIndex'),
                        song: song,
                        leading: IconButton(
                          icon: const Icon(
                            Icons.remove_rounded,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _danger,
                            fixedSize: const Size(34, 34),
                            minimumSize: const Size(34, 34),
                          ),
                          onPressed: () =>
                              playerNotifier.removeFromQueue(playlistIndex),
                        ),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle_rounded,
                            color: Color(0xFF5F5F63),
                            size: 34,
                          ),
                        ),
                        onTap: () => playerNotifier.playAtIndex(playlistIndex),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.isShuffleEnabled,
    required this.isRepeatEnabled,
    required this.onClose,
    required this.onShuffle,
    required this.onRepeat,
  });

  final bool isShuffleEnabled;
  final bool isRepeatEnabled;
  final VoidCallback onClose;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const Expanded(
            child: Text(
              'Next Up',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              color: isShuffleEnabled
                  ? FullPlayerColors.accent
                  : Colors.white70,
              size: 30,
            ),
          ),
          IconButton(
            onPressed: onRepeat,
            icon: Icon(
              Icons.repeat_rounded,
              color: isRepeatEnabled ? FullPlayerColors.accent : Colors.white70,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QueueSongTile extends StatelessWidget {
  const _QueueSongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.leading,
    this.trailing,
    this.isCurrent = false,
  });

  final SongEntity song;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 42, child: leading),
            const SizedBox(width: 8),
            _Artwork(imageUrl: song.imageUrl, isCurrent: isCurrent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AudioQueueSheet._muted,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 40, child: trailing),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.imageUrl, required this.isCurrent});

  final String imageUrl;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 58,
            height: 58,
            child: imageUrl.isEmpty
                ? const ColoredBox(
                    color: Color(0xFF2A2A2D),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: Colors.white54,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFF2A2A2D),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  ),
          ),
        ),
        if (isCurrent)
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
      ],
    );
  }
}

class FullPlayerColors {
  const FullPlayerColors._();

  static const Color accent = Color(0xFFFF6A00);
}
