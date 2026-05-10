import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/listening_history_entry_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';

class RecentsTab extends ConsumerWidget {
  const RecentsTab({super.key});

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final recentState = ref.read(recentNotifierProvider);
    final count = recentState.entries.length;

    if (count == 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            l10n.clearHistoryTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(l10n.clearHistoryConfirmation(count)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.clearHistoryLabel),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(recentNotifierProvider.notifier).clearRecents();
    if (!context.mounted) {
      return;
    }

    final updatedState = ref.read(recentNotifierProvider);
    if (updatedState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      ref.read(recentNotifierProvider.notifier).clearError();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.historyClearedMessage)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentState = ref.watch(recentNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    if (recentState.isLoading && recentState.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recentState.errorMessage != null && recentState.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 30,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.historyLoadErrorTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recentState.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.read(recentNotifierProvider.notifier).refresh();
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (recentState.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.historyEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final continueListening = recentState.continueListening;
    final recentlyPlayed = recentState.recentlyPlayed;
    final mostPlayed = recentState.mostPlayed;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _HistoryHeader(
          totalCount: recentState.entries.length,
          continueCount: continueListening.length,
          isClearing: recentState.isClearing,
          onClear: () => _clearHistory(context, ref),
        ),
        if (continueListening.isNotEmpty) ...[
          const SizedBox(height: 18),
          _HistorySectionHeader(
            title: l10n.historyContinueListeningLabel,
            icon: Icons.play_circle_outline_rounded,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < continueListening.length; index++) ...[
            _ContinueListeningCard(
              entry: continueListening[index],
              playlist: [for (final item in continueListening) item.song],
            ),
            if (index < continueListening.length - 1)
              const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 18),
        _HistorySectionHeader(
          title: l10n.historyRecentlyPlayedLabel,
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < recentlyPlayed.length; index++) ...[
          _HistorySongCard(
            entry: recentlyPlayed[index],
            playlist: [for (final item in recentlyPlayed) item.song],
            badge: _MetaChip(
              label: _formatLastPlayed(
                context,
                recentlyPlayed[index].lastPlayedAt,
              ),
              color: const Color(0xFF0EA5E9),
            ),
          ),
          if (index < recentlyPlayed.length - 1) const SizedBox(height: 12),
        ],
        if (mostPlayed.isNotEmpty) ...[
          const SizedBox(height: 18),
          _HistorySectionHeader(
            title: l10n.historyMostPlayedLabel,
            icon: Icons.local_fire_department_outlined,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < mostPlayed.length; index++) ...[
            _HistorySongCard(
              entry: mostPlayed[index],
              playlist: [for (final item in mostPlayed) item.song],
              badge: _MetaChip(
                label: l10n.playsCount(mostPlayed[index].playCount.toString()),
                color: const Color(0xFFF97316),
              ),
            ),
            if (index < mostPlayed.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.totalCount,
    required this.continueCount,
    required this.isClearing,
    required this.onClear,
  });

  final int totalCount;
  final int continueCount;
  final bool isClearing;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.historyLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          label: l10n.trackCount(totalCount),
                          color: const Color(0xFF0EA5E9),
                        ),
                        if (continueCount > 0)
                          _MetaChip(
                            label: l10n.historyContinueCount(continueCount),
                            color: const Color(0xFF8C52FF),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: isClearing ? null : onClear,
                icon: const Icon(Icons.clear_all_rounded),
                label: Text(l10n.clearHistoryLabel),
              ),
            ],
          ),
          if (isClearing) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

class _HistorySectionHeader extends StatelessWidget {
  const _HistorySectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF20202B)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF20202B),
          ),
        ),
      ],
    );
  }
}

class _ContinueListeningCard extends ConsumerWidget {
  const _ContinueListeningCard({required this.entry, required this.playlist});

  final ListeningHistoryEntryEntity entry;
  final List<SongEntity> playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final playback = ref.watch(audioPlaybackForSongProvider(entry.song.id));
    final isFavorite = ref.watch(isFavoriteSongProvider(entry.song.id));
    final isFavoriteBusy = ref.watch(isFavoriteSongBusyProvider(entry.song.id));
    final progress = entry.progress.clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SongArtwork(
                imageUrl: entry.song.imageUrl,
                fallbackIcon: Icons.play_circle_outline_rounded,
                backgroundColor: const Color(0xFF8C52FF),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF20202B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetaChip(
                          label: l10n.historyResumeFrom(
                            _formatDuration(entry.lastPosition),
                          ),
                          color: const Color(0xFF8C52FF),
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          label: '${(progress * 100).round()}%',
                          color: const Color(0xFF0EA5E9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isFavoriteBusy
                    ? null
                    : () {
                        ref
                            .read(favoriteNotifierProvider.notifier)
                            .toggleFavorite(entry.song);
                      },
                icon: isFavoriteBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF43F5E),
                        ),
                      )
                    : Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? const Color(0xFFF43F5E)
                            : Colors.grey.shade400,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9E4F7),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8C52FF)),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () {
                if (playback.isPlaying) {
                  ref.read(audioPlayerNotifierProvider.notifier).pause();
                  return;
                }

                if (playback.isCurrentSong) {
                  ref.read(audioPlayerNotifierProvider.notifier).resume();
                  return;
                }

                ref
                    .read(audioPlayerNotifierProvider.notifier)
                    .playSong(
                      entry.song,
                      playlist: playlist,
                      initialPosition: entry.lastPosition,
                    );
              },
              icon: Icon(
                playback.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(l10n.historyContinueListeningLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySongCard extends ConsumerWidget {
  const _HistorySongCard({
    required this.entry,
    required this.playlist,
    required this.badge,
  });

  final ListeningHistoryEntryEntity entry;
  final List<SongEntity> playlist;
  final Widget badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioPlaybackForSongProvider(entry.song.id));
    final isFavorite = ref.watch(isFavoriteSongProvider(entry.song.id));
    final isFavoriteBusy = ref.watch(isFavoriteSongBusyProvider(entry.song.id));

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
          _SongArtwork(
            imageUrl: entry.song.imageUrl,
            fallbackIcon: Icons.music_note,
            backgroundColor: const Color(0xFF0EA5E9),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.song.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.song.artist,
                  style: const TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                badge,
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isFavoriteBusy
                ? null
                : () {
                    ref
                        .read(favoriteNotifierProvider.notifier)
                        .toggleFavorite(entry.song);
                  },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: isFavoriteBusy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFF43F5E),
                      ),
                    )
                  : Icon(
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
              if (playback.isPlaying) {
                ref.read(audioPlayerNotifierProvider.notifier).pause();
              } else if (playback.isCurrentSong) {
                ref.read(audioPlayerNotifierProvider.notifier).resume();
              } else {
                ref
                    .read(audioPlayerNotifierProvider.notifier)
                    .playSong(entry.song, playlist: playlist);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: playback.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0EA5E9),
                      ),
                    )
                  : Icon(
                      playback.isPlaying
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      color: playback.isPlaying
                          ? const Color(0xFF0EA5E9)
                          : Colors.grey.shade400,
                      size: 28,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongArtwork extends StatelessWidget {
  const _SongArtwork({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.backgroundColor,
  });

  final String imageUrl;
  final IconData fallbackIcon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Icon(fallbackIcon, color: Colors.white54, size: 28),
            )
          : Icon(fallbackIcon, color: Colors.white54, size: 28),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  return '$minutes:$seconds';
}

String _formatLastPlayed(BuildContext context, DateTime? lastPlayedAt) {
  final l10n = AppLocalizations.of(context)!;
  if (lastPlayedAt == null) {
    return l10n.historyPlayedRecentlyLabel;
  }

  final difference = DateTime.now().difference(lastPlayedAt);
  if (difference.inMinutes < 1) {
    return l10n.historyPlayedRecentlyLabel;
  }

  if (difference.inHours < 1) {
    return l10n.historyPlayedMinutesAgo(difference.inMinutes);
  }

  if (difference.inDays < 1) {
    return l10n.historyPlayedHoursAgo(difference.inHours);
  }

  return l10n.historyPlayedDaysAgo(difference.inDays);
}
