import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/playlist_provider.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});

  static const Color _background = Color(0xFFF7F3FB);
  static const Color _primary = Color(0xFFA066FF);
  static const Color _secondary = Color(0xFFCDAEFF);
  static const Color _textPrimary = Color(0xFF20202B);
  static const Color _textMuted = Color(0xFF8E889C);

  final PlaylistEntity playlist;

  PlaylistEntity? _resolveCurrentPlaylist(PlaylistState state) {
    for (final item in state.playlists) {
      if (item.id == playlist.id) {
        return item;
      }
    }

    return null;
  }

  List<SongEntity> _resolvePlaylistSongs(
    SongState state,
    PlaylistEntity currentPlaylist,
  ) {
    if (state is! SongLoaded || currentPlaylist.songIds.isEmpty) {
      return const [];
    }

    final songsById = <String, SongEntity>{
      for (final song in state.songs) song.id: song,
    };

    return currentPlaylist.songIds
        .map((id) => songsById[id])
        .whereType<SongEntity>()
        .toList();
  }

  Future<void> _showSongPicker(
    BuildContext context,
    WidgetRef ref,
    PlaylistEntity currentPlaylist,
    List<SongEntity> allSongs,
  ) async {
    final selectedIds = Set<String>.from(currentPlaylist.songIds);
    final l10n = AppLocalizations.of(context)!;

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.55,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Thêm bài hát',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: Text(l10n.cancel),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                final orderedSongIds = <String>[
                                  ...currentPlaylist.songIds.where(
                                    selectedIds.contains,
                                  ),
                                  ...allSongs
                                      .map((song) => song.id)
                                      .where(
                                        (id) =>
                                            selectedIds.contains(id) &&
                                            !currentPlaylist.songIds.contains(
                                              id,
                                            ),
                                      ),
                                ];
                                Navigator.of(sheetContext).pop(orderedSongIds);
                              },
                              child: Text(l10n.saveChanges),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: allSongs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final song = allSongs[index];
                            final isSelected = selectedIds.contains(song.id);

                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedIds.remove(song.id);
                                    } else {
                                      selectedIds.add(song.id);
                                    }
                                  });
                                },
                                child: Ink(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? _primary.withValues(alpha: 0.28)
                                          : _secondary.withValues(alpha: 0.2),
                                    ),
                                    color: isSelected
                                        ? _primary.withValues(alpha: 0.06)
                                        : Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          color: _primary.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: song.imageUrl.isNotEmpty
                                            ? Image.network(
                                                song.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(
                                                      Icons.music_note_rounded,
                                                      color: _primary,
                                                      size: 24,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.music_note_rounded,
                                                color: _primary,
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: _textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              song.artist,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: _textMuted,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (_) {
                                          setModalState(() {
                                            if (isSelected) {
                                              selectedIds.remove(song.id);
                                            } else {
                                              selectedIds.add(song.id);
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .savePlaylistSongs(playlistId: currentPlaylist.id, songIds: result);

    if (!context.mounted) {
      return;
    }

    final playlistState = ref.read(playlistNotifierProvider);
    if (!success && playlistState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(playlistState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã cập nhật playlist.')));
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistEntity currentPlaylist,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Xóa playlist',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bạn có chắc muốn xóa playlist "${currentPlaylist.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .deletePlaylist(currentPlaylist.id);

    if (!context.mounted) {
      return;
    }

    final playlistState = ref.read(playlistNotifierProvider);
    if (!success && playlistState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(playlistState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa playlist.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playlistState = ref.watch(playlistNotifierProvider);
    final songState = ref.watch(songNotifierProvider);
    final currentPlaylist = _resolveCurrentPlaylist(playlistState) ?? playlist;
    final playlistSongs = _resolvePlaylistSongs(songState, currentPlaylist);
    final allSongs = songState is SongLoaded
        ? songState.songs
        : const <SongEntity>[];

    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9F7FD), Color(0xFFF3EDF9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    _HeaderIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        playlist.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _HeaderIconButton(
                      icon: Icons.playlist_add_rounded,
                      onPressed: songState is! SongLoaded
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Danh sách bài hát chưa sẵn sàng. Vui lòng thử lại sau.',
                                  ),
                                ),
                              );
                            }
                          : () => _showSongPicker(
                              context,
                              ref,
                              currentPlaylist,
                              allSongs,
                            ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deletePlaylist(context, ref, currentPlaylist);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Xóa playlist',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: const _HeaderIconButton(
                        icon: Icons.more_horiz_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                  children: [
                    _PlaylistHeroCard(playlist: currentPlaylist),
                    const SizedBox(height: 18),
                    _PlaylistMetaRow(
                      label: l10n.trackCount(playlistSongs.length),
                      actionLabel: 'Phát playlist',
                      actionEnabled: playlistSongs.isNotEmpty,
                      onActionPressed: playlistSongs.isEmpty
                          ? null
                          : () {
                              ref
                                  .read(audioPlayerNotifierProvider.notifier)
                                  .playSong(
                                    playlistSongs.first,
                                    playlist: playlistSongs,
                                  );
                              ref
                                  .read(recentNotifierProvider.notifier)
                                  .addRecent(playlistSongs.first);
                            },
                    ),
                    const SizedBox(height: 18),
                    if (songState is SongLoading || songState is SongInitial)
                      const _StatusCard(
                        child: CircularProgressIndicator(color: _primary),
                      )
                    else if (songState is SongError)
                      _StatusCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              songState.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: () {
                                ref
                                    .read(songNotifierProvider.notifier)
                                    .loadSongs();
                              },
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    else if (playlistSongs.isEmpty)
                      const _StatusCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.library_music_rounded,
                              color: _primary,
                              size: 32,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Playlist này chưa có bài hát nào.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      for (
                        var index = 0;
                        index < playlistSongs.length;
                        index++
                      ) ...[
                        _PlaylistSongTile(
                          song: playlistSongs[index],
                          playlistSongs: playlistSongs,
                        ),
                        if (index < playlistSongs.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistHeroCard extends StatelessWidget {
  const _PlaylistHeroCard({required this.playlist});

  final PlaylistEntity playlist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = _playlistPalette(playlist.name);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.last.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              top: -28,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 24,
              child: _ArtworkFallback(
                label: _playlistMonogram(playlist.name),
                size: 84,
              ),
            ),
            Positioned(
              left: 24,
              top: 26,
              child: Text(
                l10n.playlistsLabel.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 120,
              bottom: 52,
              child: Text(
                playlist.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              child: Text(
                l10n.trackCount(playlist.trackCount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistMetaRow extends StatelessWidget {
  const _PlaylistMetaRow({
    required this.label,
    required this.actionLabel,
    required this.actionEnabled,
    this.onActionPressed,
  });

  final String label;
  final String actionLabel;
  final bool actionEnabled;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PlaylistDetailScreen._textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: actionEnabled ? onActionPressed : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _PlaylistSongTile extends ConsumerWidget {
  const _PlaylistSongTile({required this.song, required this.playlistSongs});

  final SongEntity song;
  final List<SongEntity> playlistSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playback = ref.watch(audioPlaybackForSongProvider(song.id));
    final isCurrentSong = playback.isCurrentSong;
    final isPlayingThisSong = playback.isPlaying;
    final isLoadingThisSong = playback.isLoading;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PlaylistDetailScreen._secondary.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: PlaylistDetailScreen._primary.withValues(alpha: 0.12),
            ),
            clipBehavior: Clip.antiAlias,
            child: song.imageUrl.isNotEmpty
                ? Image.network(
                    song.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.music_note_rounded,
                      color: PlaylistDetailScreen._primary,
                      size: 26,
                    ),
                  )
                : const Icon(
                    Icons.music_note_rounded,
                    color: PlaylistDetailScreen._primary,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: PlaylistDetailScreen._textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: PlaylistDetailScreen._textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(favoriteNotifierProvider.notifier).toggleFavorite(song);
            },
            icon: Icon(
              ref
                      .watch(favoriteNotifierProvider)
                      .any((item) => item.id == song.id)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: PlaylistDetailScreen._primary,
            ),
          ),
          IconButton(
            onPressed: () {
              if (isPlayingThisSong) {
                ref.read(audioPlayerNotifierProvider.notifier).pause();
                return;
              }

              if (isCurrentSong) {
                ref.read(audioPlayerNotifierProvider.notifier).resume();
                return;
              }

              ref
                  .read(audioPlayerNotifierProvider.notifier)
                  .playSong(song, playlist: playlistSongs);
              ref.read(recentNotifierProvider.notifier).addRecent(song);
            },
            icon: isLoadingThisSong
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PlaylistDetailScreen._primary,
                    ),
                  )
                : Icon(
                    isPlayingThisSong
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 28,
                    color: isCurrentSong
                        ? PlaylistDetailScreen._primary
                        : PlaylistDetailScreen._textMuted,
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null
                ? PlaylistDetailScreen._textMuted
                : PlaylistDetailScreen._textPrimary,
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

List<Color> _playlistPalette(String seed) {
  const palettes = [
    [Color(0xFF6654FF), Color(0xFFA36CFF)],
    [Color(0xFF247BA0), Color(0xFF70C1B3)],
    [Color(0xFF7A3E65), Color(0xFFE76F51)],
    [Color(0xFF214E34), Color(0xFF6E9F6D)],
    [Color(0xFF2D3047), Color(0xFF7D8597)],
  ];

  final code = seed.codeUnits.fold<int>(0, (total, unit) => total + unit);
  return palettes[code % palettes.length];
}

String _playlistMonogram(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return 'PL';
  }

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
}
