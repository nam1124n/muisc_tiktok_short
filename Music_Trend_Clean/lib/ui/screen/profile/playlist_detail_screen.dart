import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/playlist_provider.dart';

String? _playlistErrorText(BuildContext context, PlaylistState state) {
  final l10n = AppLocalizations.of(context)!;

  if (state.errorMessage != null) {
    return state.errorMessage;
  }

  return switch (state.errorType) {
    PlaylistErrorType.emptyName => l10n.playlistErrorEmptyName,
    PlaylistErrorType.playlistNotFound => l10n.playlistErrorNotFound,
    PlaylistErrorType.authenticationRequiredForCreate =>
      l10n.playlistErrorAuthenticationRequiredForCreate,
    PlaylistErrorType.authenticationRequiredForUpdate =>
      l10n.playlistErrorAuthenticationRequiredForUpdate,
    PlaylistErrorType.authenticationRequiredForDelete =>
      l10n.playlistErrorAuthenticationRequiredForDelete,
    null => null,
  };
}

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
                            Expanded(
                              child: Text(
                                l10n.addSongsToPlaylistTitle,
                                style: const TextStyle(
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
    final errorMessage = _playlistErrorText(context, playlistState);
    if (!success && errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.playlistUpdatedMessage)));
  }

  Future<void> _deletePlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistEntity currentPlaylist,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            l10n.deletePlaylistTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(l10n.deletePlaylistConfirmation(currentPlaylist.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteLabel),
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
    final errorMessage = _playlistErrorText(context, playlistState);
    if (!success && errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.playlistDeletedMessage)));
  }

  Future<void> _editPlaylistDetails(
    BuildContext context,
    WidgetRef ref,
    PlaylistEntity currentPlaylist,
    List<SongEntity> playlistSongs,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: currentPlaylist.name);
    final descriptionController = TextEditingController(
      text: currentPlaylist.description,
    );
    final coverCandidates = {
      for (final song in playlistSongs)
        if (song.imageUrl.isNotEmpty) song.imageUrl,
    }.toList(growable: false);

    final result = await showModalBottomSheet<_PlaylistDetailsDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var selectedCoverUrl = currentPlaylist.coverUrl;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.editPlaylistDetailsTitle,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.playlistNameLabel,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: descriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: l10n.playlistDescriptionLabel,
                            hintText: l10n.playlistDescriptionHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.playlistCoverLabel,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _CoverChoiceTile(
                              isSelected: selectedCoverUrl.isEmpty,
                              imageUrl: '',
                              label: l10n.playlistCoverNoneOption,
                              onTap: () {
                                setModalState(() {
                                  selectedCoverUrl = '';
                                });
                              },
                            ),
                            for (final coverUrl in coverCandidates)
                              _CoverChoiceTile(
                                isSelected: selectedCoverUrl == coverUrl,
                                imageUrl: coverUrl,
                                label: l10n.playlistCoverFromSongOption,
                                onTap: () {
                                  setModalState(() {
                                    selectedCoverUrl = coverUrl;
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                child: Text(l10n.cancel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop(
                                    _PlaylistDetailsDraft(
                                      name: nameController.text,
                                      description: descriptionController.text,
                                      coverUrl: selectedCoverUrl,
                                    ),
                                  );
                                },
                                child: Text(l10n.saveChanges),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (result == null) {
      return;
    }

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .updatePlaylistDetails(
          playlistId: currentPlaylist.id,
          name: result.name,
          description: result.description,
          coverUrl: result.coverUrl,
        );

    if (!context.mounted) {
      return;
    }

    final playlistState = ref.read(playlistNotifierProvider);
    final errorMessage = _playlistErrorText(context, playlistState);
    if (!success && errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.playlistDetailsUpdatedMessage)));
  }

  Future<void> _reorderPlaylistSongs(
    BuildContext context,
    WidgetRef ref, {
    required PlaylistEntity currentPlaylist,
    required List<SongEntity> playlistSongs,
    required int oldIndex,
    required int newIndex,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (oldIndex == newIndex) {
      return;
    }

    final adjustedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    final reorderedSongIds = [...currentPlaylist.songIds];
    final movedSongId = reorderedSongIds.removeAt(oldIndex);
    reorderedSongIds.insert(adjustedNewIndex, movedSongId);

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .savePlaylistSongs(
          playlistId: currentPlaylist.id,
          songIds: reorderedSongIds,
        );

    if (!context.mounted) {
      return;
    }

    final playlistState = ref.read(playlistNotifierProvider);
    final errorMessage = _playlistErrorText(context, playlistState);
    if (!success && errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    if (playlistSongs.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.playlistUpdatedMessage)));
    }
  }

  Future<void> _removeSongFromPlaylist(
    BuildContext context,
    WidgetRef ref, {
    required PlaylistEntity currentPlaylist,
    required SongEntity song,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            l10n.removeSongFromPlaylistTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            l10n.removeSongFromPlaylistConfirmation(
              song.title,
              currentPlaylist.name,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteLabel),
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
        .removeSongFromPlaylist(
          playlistId: currentPlaylist.id,
          songId: song.id,
        );

    if (!context.mounted) {
      return;
    }

    final playlistState = ref.read(playlistNotifierProvider);
    final errorMessage = _playlistErrorText(context, playlistState);
    if (!success && errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.songRemovedFromPlaylistMessage(song.title))),
    );
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
                        currentPlaylist.name,
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
                                SnackBar(
                                  content: Text(l10n.songListNotReadyMessage),
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
                        if (value == 'edit') {
                          _editPlaylistDetails(
                            context,
                            ref,
                            currentPlaylist,
                            playlistSongs,
                          );
                        } else if (value == 'delete') {
                          _deletePlaylist(context, ref, currentPlaylist);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color: _textPrimary,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                l10n.editPlaylistDetailsTitle,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
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
                                l10n.deletePlaylistTitle,
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
              if (playlistState.isSaving)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                  children: [
                    _PlaylistHeroCard(playlist: currentPlaylist),
                    const SizedBox(height: 18),
                    _PlaylistMetaRow(
                      label: l10n.trackCount(playlistSongs.length),
                      actionLabel: l10n.playPlaylistAction,
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
                            },
                    ),
                    if (currentPlaylist.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        currentPlaylist.description,
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (songState is SongLoading || songState is SongInitial)
                      _StatusCard(
                        child: _DetailStatusContent(
                          icon: Icons.graphic_eq_rounded,
                          title: l10n.playlistSongsLoadingTitle,
                          subtitle: l10n.playlistSongsLoadingSubtitle,
                          trailing: CircularProgressIndicator(color: _primary),
                        ),
                      )
                    else if (songState is SongError)
                      _StatusCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.playlistSongsLoadErrorTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                      _StatusCard(
                        child: _DetailStatusContent(
                          icon: Icons.library_music_rounded,
                          title: l10n.playlistSongsEmptyTitle,
                          subtitle: l10n.playlistSongsEmptySubtitle,
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.drag_indicator_rounded,
                              color: _textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.playlistReorderHint,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: playlistSongs.length,
                        onReorder: (oldIndex, newIndex) {
                          _reorderPlaylistSongs(
                            context,
                            ref,
                            currentPlaylist: currentPlaylist,
                            playlistSongs: playlistSongs,
                            oldIndex: oldIndex,
                            newIndex: newIndex,
                          );
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            key: ValueKey(playlistSongs[index].id),
                            padding: EdgeInsets.only(
                              bottom: index == playlistSongs.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _PlaylistSongTile(
                              song: playlistSongs[index],
                              playlistSongs: playlistSongs,
                              reorderIndex: index,
                              onRemove: () => _removeSongFromPlaylist(
                                context,
                                ref,
                                currentPlaylist: currentPlaylist,
                                song: playlistSongs[index],
                              ),
                            ),
                          );
                        },
                      ),
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
              child: playlist.coverUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        playlist.coverUrl,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _ArtworkFallback(
                          label: _playlistMonogram(playlist.name),
                          size: 84,
                        ),
                      ),
                    )
                  : _ArtworkFallback(
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
              bottom: playlist.description.trim().isEmpty ? 52 : 78,
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
            if (playlist.description.trim().isNotEmpty)
              Positioned(
                left: 24,
                right: 120,
                bottom: 44,
                child: Text(
                  playlist.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _PlaylistDetailsDraft {
  const _PlaylistDetailsDraft({
    required this.name,
    required this.description,
    required this.coverUrl,
  });

  final String name;
  final String description;
  final String coverUrl;
}

class _CoverChoiceTile extends StatelessWidget {
  const _CoverChoiceTile({
    required this.isSelected,
    required this.imageUrl,
    required this.label,
    required this.onTap,
  });

  final bool isSelected;
  final String imageUrl;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: 90,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? PlaylistDetailScreen._primary
                  : PlaylistDetailScreen._secondary.withValues(alpha: 0.24),
              width: isSelected ? 1.6 : 1,
            ),
            color: isSelected
                ? PlaylistDetailScreen._primary.withValues(alpha: 0.08)
                : Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: PlaylistDetailScreen._primary.withValues(alpha: 0.12),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.photo_rounded,
                          color: PlaylistDetailScreen._primary,
                        ),
                      )
                    : const Icon(
                        Icons.layers_clear_rounded,
                        color: PlaylistDetailScreen._primary,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PlaylistDetailScreen._textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistSongTile extends ConsumerWidget {
  const _PlaylistSongTile({
    required this.song,
    required this.playlistSongs,
    required this.reorderIndex,
    required this.onRemove,
  });

  final SongEntity song;
  final List<SongEntity> playlistSongs;
  final int reorderIndex;
  final VoidCallback onRemove;

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
            tooltip: AppLocalizations.of(context)!.removeFromPlaylistTooltip,
            onPressed: onRemove,
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              color: Colors.redAccent,
            ),
          ),
          IconButton(
            onPressed: ref.watch(isFavoriteSongBusyProvider(song.id))
                ? null
                : () {
                    ref
                        .read(favoriteNotifierProvider.notifier)
                        .toggleFavorite(song);
                  },
            icon: ref.watch(isFavoriteSongBusyProvider(song.id))
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PlaylistDetailScreen._primary,
                    ),
                  )
                : Icon(
                    ref.watch(isFavoriteSongProvider(song.id))
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
          ReorderableDragStartListener(
            index: reorderIndex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.drag_handle_rounded,
                color: PlaylistDetailScreen._textMuted.withValues(alpha: 0.8),
              ),
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

class _DetailStatusContent extends StatelessWidget {
  const _DetailStatusContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PlaylistDetailScreen._primary.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: PlaylistDetailScreen._primary, size: 24),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: PlaylistDetailScreen._textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: PlaylistDetailScreen._textMuted,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (trailing != null) ...[const SizedBox(height: 18), trailing!],
      ],
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
