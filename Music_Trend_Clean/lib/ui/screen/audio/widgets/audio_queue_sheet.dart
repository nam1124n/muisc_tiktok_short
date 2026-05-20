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

  static const Color _surface = Color(0xFF111111);
  static const Color _tileSplash = Color(0xFF1B1B1D);
  static const Color _muted = Color(0xFF8A8A8F);
  static const Color _softMuted = Color(0xFF5F5F64);
  static const Color _danger = Color(0xFFE5454F);

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
                const SliverToBoxAdapter(child: SizedBox(height: 6)),
                SliverList.builder(
                  itemCount: recentlyPlayed.length,
                  itemBuilder: (context, index) {
                    final song = recentlyPlayed[index];
                    return _QueueSongTile(
                      song: song,
                      reserveLeadingSpace: false,
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
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                const SliverToBoxAdapter(
                  child: _SectionTitle('Currently playing'),
                ),
                SliverToBoxAdapter(
                  child: _QueueSongTile(
                    song: currentSong,
                    isCurrent: true,
                    reserveLeadingSpace: false,
                    onTap: () {},
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
              const SliverToBoxAdapter(child: _SectionTitle('Playing next')),
              if (nextSongs.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28, 12, 28, 8),
                    child: Text(
                      'No songs queued.',
                      style: TextStyle(color: _muted, fontSize: 14),
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
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _danger,
                            fixedSize: const Size(32, 32),
                            minimumSize: const Size(32, 32),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () =>
                              playerNotifier.removeFromQueue(playlistIndex),
                        ),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle_rounded,
                            color: _softMuted,
                            size: 28,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 30,
                ),
              ),
              const Expanded(
                child: Text(
                  'Next Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onShuffle,
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: isShuffleEnabled
                      ? FullPlayerColors.accent
                      : AudioQueueSheet._muted,
                  size: 23,
                ),
              ),
              IconButton(
                onPressed: onRepeat,
                icon: Icon(
                  Icons.repeat_rounded,
                  color: isRepeatEnabled
                      ? FullPlayerColors.accent
                      : AudioQueueSheet._muted,
                  size: 23,
                ),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AudioQueueSheet._muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
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
    this.reserveLeadingSpace = true,
  });

  final SongEntity song;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool isCurrent;
  final bool reserveLeadingSpace;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AudioQueueSheet._tileSplash,
        highlightColor: AudioQueueSheet._tileSplash,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
          child: Row(
            children: [
              if (reserveLeadingSpace) ...[
                SizedBox(width: 38, child: leading),
                const SizedBox(width: 10),
              ],
              _Artwork(imageUrl: song.imageUrl, isCurrent: isCurrent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AudioQueueSheet._muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 34, child: trailing),
            ],
          ),
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
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: imageUrl.isEmpty
                ? const ColoredBox(
                    color: Color(0xFF242426),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: Colors.white54,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFF242426),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 22,
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
