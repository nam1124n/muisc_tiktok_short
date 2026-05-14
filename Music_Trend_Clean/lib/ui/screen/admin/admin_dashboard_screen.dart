import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/admin_song_form_screen.dart';
import 'package:login_flutter/ui/screen/admin/admin_year_song_dashboard_screen.dart';
import 'package:login_flutter/ui/screen/admin/admin_generated_audio_dashboard_screen.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';

const _allSongStatusFilter = 'all';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _selectedStatusFilter = _allSongStatusFilter;
  final Set<String> _selectedSongIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _AdminSongSortOption _selectedSortOption = _AdminSongSortOption.updatedDesc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final songState = ref.watch(adminSongNotifierProvider);
    final hasAdminAccess = ref.watch(sessionHasAdminAccessProvider);
    final body = _buildBody(context, hasAdminAccess, songState);

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmbeddedAdminHeader(
            title: l10n.adminPanelTitle,
            primaryActionLabel: l10n.addSongLabel,
            primaryActionIcon: Icons.add,
            onRefresh: () =>
                ref.read(adminSongNotifierProvider.notifier).loadSongs(),
            onPrimaryAction: _openCreateSongForm,
          ),
          const SizedBox(height: 20),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          l10n.adminPanelTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8C52FF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(adminSongNotifierProvider.notifier).loadSongs(),
          ),
        ],
      ),
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'admin-year-song-dashboard',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF8C52FF),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(l10n.genreLabel),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminYearSongDashboardScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'admin-ai-audio-dashboard',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF8C52FF),
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('Nhạc AI'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminGeneratedAudioDashboardScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'admin-add-song',
            backgroundColor: const Color(0xFF8C52FF),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(l10n.addSongLabel),
            onPressed: _openCreateSongForm,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool hasAdminAccess,
    SongState songState,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (!hasAdminAccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.accessDeniedTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.accessDeniedMessage),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.goBack),
            ),
          ],
        ),
      );
    }

    if (songState is SongLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8C52FF)),
      );
    }

    if (songState is SongError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(songState.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(adminSongNotifierProvider.notifier).loadSongs(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (songState is SongLoaded) {
      if (songState.songs.isEmpty) {
        return _buildEmptyState(context);
      }

      final filteredSongs = _applySongFilters(songState.songs);
      final selectedSongs = filteredSongs
          .where((song) => _selectedSongIds.contains(song.id))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusFilters(context),
          const SizedBox(height: 16),
          _buildSearchAndSortBar(context),
          const SizedBox(height: 16),
          _buildBatchToolbar(context, filteredSongs, selectedSongs),
          const SizedBox(height: 16),
          Expanded(
            child: filteredSongs.isEmpty
                ? _buildFilterEmptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filteredSongs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      return _buildSongTile(context, song);
                    },
                  ),
          ),
        ],
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF8C52FF)),
    );
  }

  List<SongEntity> _applyStatusFilter(List<SongEntity> songs) {
    if (_selectedStatusFilter == _allSongStatusFilter) {
      return songs;
    }

    return songs.where((song) => song.status == _selectedStatusFilter).toList();
  }

  List<SongEntity> _applySongFilters(List<SongEntity> songs) {
    final statusFilteredSongs = _applyStatusFilter(songs);
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final queryFilteredSongs = normalizedQuery.isEmpty
        ? statusFilteredSongs
        : statusFilteredSongs
              .where((song) => _matchesSongSearch(song, normalizedQuery))
              .toList();

    final sortedSongs = List<SongEntity>.from(queryFilteredSongs);
    sortedSongs.sort((left, right) {
      return switch (_selectedSortOption) {
        _AdminSongSortOption.updatedAsc => _songTimestamp(
          left,
        ).compareTo(_songTimestamp(right)),
        _AdminSongSortOption.titleAsc => left.title.toLowerCase().compareTo(
          right.title.toLowerCase(),
        ),
        _AdminSongSortOption.updatedDesc => _songTimestamp(
          right,
        ).compareTo(_songTimestamp(left)),
      };
    });

    return sortedSongs;
  }

  bool _matchesSongSearch(SongEntity song, String normalizedQuery) {
    final haystack = <String>[
      song.title,
      song.artist,
      song.moderationReason,
      song.status,
    ].join(' ').toLowerCase();

    return haystack.contains(normalizedQuery);
  }

  DateTime _songTimestamp(SongEntity song) {
    return song.updatedAt ??
        song.savedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _buildStatusFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filterOptions = [
      (_allSongStatusFilter, l10n.adminFilterAll),
      (SongStatuses.published, l10n.adminFilterPublished),
      (SongStatuses.pending, l10n.adminFilterPending),
      (SongStatuses.hidden, l10n.adminFilterHidden),
      (SongStatuses.archived, l10n.adminFilterArchived),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (value, label) in filterOptions) ...[
            ChoiceChip(
              label: Text(label),
              selected: _selectedStatusFilter == value,
              onSelected: (_) {
                setState(() {
                  _selectedStatusFilter = value;
                  _selectedSongIds.clear();
                });
              },
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndSortBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final searchField = TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _selectedSongIds.clear();
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.adminSearchHint,
            ),
          );
          final sortDropdown = DropdownButtonFormField<_AdminSongSortOption>(
            initialValue: _selectedSortOption,
            decoration: InputDecoration(labelText: l10n.adminSortLabel),
            items: [
              DropdownMenuItem(
                value: _AdminSongSortOption.updatedDesc,
                child: Text(l10n.adminSortUpdatedNewest),
              ),
              DropdownMenuItem(
                value: _AdminSongSortOption.updatedAsc,
                child: Text(l10n.adminSortUpdatedOldest),
              ),
              DropdownMenuItem(
                value: _AdminSongSortOption.titleAsc,
                child: Text(l10n.adminSortTitleAsc),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedSortOption = value;
              });
            },
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 3, child: searchField),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: sortDropdown),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [searchField, const SizedBox(height: 12), sortDropdown],
          );
        },
      ),
    );
  }

  Widget _buildBatchToolbar(
    BuildContext context,
    List<SongEntity> filteredSongs,
    List<SongEntity> selectedSongs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final allVisibleSelected =
        filteredSongs.isNotEmpty &&
        selectedSongs.length == filteredSongs.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminBatchActionsTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selectedSongs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.adminSelectedItemsSummary(selectedSongs.length),
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: filteredSongs.isEmpty
                    ? null
                    : () => _toggleVisibleSelection(filteredSongs),
                icon: Icon(
                  allVisibleSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                ),
                label: Text(
                  allVisibleSelected
                      ? l10n.adminClearSelectionAction
                      : l10n.adminSelectAllVisibleAction,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: selectedSongs.isEmpty
                    ? null
                    : () => _handleBatchAction(
                        context,
                        selectedSongs,
                        _AdminSongAction.publish,
                      ),
                icon: const Icon(Icons.public_rounded),
                label: Text(l10n.publishSongAction),
              ),
              FilledButton.tonalIcon(
                onPressed: selectedSongs.isEmpty
                    ? null
                    : () => _handleBatchAction(
                        context,
                        selectedSongs,
                        _AdminSongAction.hide,
                      ),
                icon: const Icon(Icons.visibility_off_rounded),
                label: Text(l10n.hideSongAction),
              ),
              FilledButton.tonalIcon(
                onPressed: selectedSongs.isEmpty
                    ? null
                    : () => _handleBatchAction(
                        context,
                        selectedSongs,
                        _AdminSongAction.restore,
                      ),
                icon: const Icon(Icons.settings_backup_restore_rounded),
                label: Text(l10n.restoreSongAction),
              ),
              OutlinedButton.icon(
                onPressed: selectedSongs.isEmpty
                    ? null
                    : () => _handleBatchAction(
                        context,
                        selectedSongs,
                        _AdminSongAction.archive,
                      ),
                icon: const Icon(Icons.archive_outlined),
                label: Text(l10n.archiveSongAction),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, SongEntity song) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedSongIds.contains(song.id);
    final moderationReason = song.moderationReason.trim();
    final updatedAtLabel = _formatUpdatedAt(l10n, _songTimestamp(song));
    final moderationMetaLabel = _formatModerationMeta(l10n, song);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _toggleSongSelection(song.id, !isSelected),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: song.imageUrl.isNotEmpty
              ? Image.network(
                  song.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholderIcon(),
                )
              : _placeholderIcon(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _SongStatusBadge(song: song),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.artist,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                updatedAtLabel,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              if (moderationMetaLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  moderationMetaLabel,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
              if (moderationReason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${l10n.adminModerationReasonLabel}: $moderationReason',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9A6700),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) =>
                  _toggleSongSelection(song.id, value ?? false),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF8C52FF)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminSongFormScreen(initialSong: song),
                  ),
                );
              },
            ),
            PopupMenuButton<_AdminSongAction>(
              onSelected: (action) => _handleSongAction(context, song, action),
              itemBuilder: (context) => _buildActionItems(context, song),
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<_AdminSongAction>> _buildActionItems(
    BuildContext context,
    SongEntity song,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final items = <PopupMenuEntry<_AdminSongAction>>[];

    if (song.isArchived) {
      items.add(
        PopupMenuItem(
          value: _AdminSongAction.restore,
          child: Text(l10n.restoreSongAction),
        ),
      );
    } else {
      if (song.isPublished) {
        items.add(
          PopupMenuItem(
            value: _AdminSongAction.hide,
            child: Text(l10n.hideSongAction),
          ),
        );
      } else {
        items.add(
          PopupMenuItem(
            value: _AdminSongAction.publish,
            child: Text(l10n.publishSongAction),
          ),
        );
      }

      items.add(
        PopupMenuItem(
          value: _AdminSongAction.archive,
          child: Text(l10n.archiveSongAction),
        ),
      );
    }

    return items;
  }

  Widget _placeholderIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note, color: Color(0xFF8C52FF), size: 28),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.library_music_outlined,
              size: 64,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noSongsYetTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noSongsYetSubtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_alt_off_outlined, size: 56),
          const SizedBox(height: 16),
          Text(
            l10n.adminNoSongsForFilterTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.adminNoSongsForFilterSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSongAction(
    BuildContext context,
    SongEntity song,
    _AdminSongAction action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(adminSongNotifierProvider.notifier);
    final moderatedBy = ref.read(sessionProvider).email;

    if (action == _AdminSongAction.archive) {
      final moderationReason = await _promptModerationReason(
        context,
        title: l10n.archiveSongTitle,
        hintText: l10n.adminArchiveReasonHint,
        presets: _archiveReasonPresets(l10n),
      );
      if (moderationReason == null) {
        return;
      }

      await notifier.updateSongModeration(
        song,
        status: SongStatuses.archived,
        moderationReason: moderationReason,
        moderatedBy: moderatedBy,
      );
    } else if (action == _AdminSongAction.hide) {
      final moderationReason = await _promptModerationReason(
        context,
        title: l10n.hideSongAction,
        hintText: l10n.adminModerationReasonHint,
        presets: _hideReasonPresets(l10n),
      );
      if (moderationReason == null) {
        return;
      }

      await notifier.updateSongModeration(
        song,
        status: SongStatuses.hidden,
        moderationReason: moderationReason,
        moderatedBy: moderatedBy,
      );
    } else {
      await notifier.updateSongModeration(
        song,
        status: SongStatuses.published,
        moderationReason: '',
        moderatedBy: moderatedBy,
      );
    }

    if (!context.mounted) {
      return;
    }

    _handleActionResult(context);
  }

  Future<void> _handleBatchAction(
    BuildContext context,
    List<SongEntity> selectedSongs,
    _AdminSongAction action,
  ) async {
    if (selectedSongs.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(adminSongNotifierProvider.notifier);
    final moderatedBy = ref.read(sessionProvider).email;

    if (action == _AdminSongAction.archive) {
      final moderationReason = await _promptModerationReason(
        context,
        title: l10n.archiveSongTitle,
        hintText: l10n.adminArchiveReasonHint,
        presets: _archiveReasonPresets(l10n),
      );
      if (moderationReason == null) {
        return;
      }

      await notifier.updateSongsModerationBatch(
        selectedSongs,
        status: SongStatuses.archived,
        moderationReason: moderationReason,
        moderatedBy: moderatedBy,
      );
    } else if (action == _AdminSongAction.hide) {
      final moderationReason = await _promptModerationReason(
        context,
        title: l10n.hideSongAction,
        hintText: l10n.adminModerationReasonHint,
        presets: _hideReasonPresets(l10n),
      );
      if (moderationReason == null) {
        return;
      }

      await notifier.updateSongsModerationBatch(
        selectedSongs,
        status: SongStatuses.hidden,
        moderationReason: moderationReason,
        moderatedBy: moderatedBy,
      );
    } else {
      await notifier.updateSongsModerationBatch(
        selectedSongs,
        status: SongStatuses.published,
        moderationReason: '',
        moderatedBy: moderatedBy,
      );
    }

    if (!context.mounted) {
      return;
    }

    _handleActionResult(context);
  }

  void _handleActionResult(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final songState = ref.read(adminSongNotifierProvider);

    if (songState is SongError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorLabel}: ${songState.message}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.actionSuccessMessage),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _selectedSongIds.clear();
    });
    ref.read(adminSongNotifierProvider.notifier).loadSongs();
  }

  Future<String?> _promptModerationReason(
    BuildContext context, {
    required String title,
    required String hintText,
    required List<String> presets,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in presets)
                      ActionChip(
                        label: Text(preset),
                        onPressed: () {
                          controller.text = preset;
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.adminModerationReasonLabel,
                    hintText: hintText,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.adminModerationReasonRequiredMessage;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.pop(dialogCtx, controller.text.trim());
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  String _formatUpdatedAt(AppLocalizations l10n, DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return l10n.adminUpdatedAtLabel('${value.year}-$month-$day $hour:$minute');
  }

  String? _formatModerationMeta(AppLocalizations l10n, SongEntity song) {
    if (song.moderatedBy.trim().isEmpty && song.moderatedAt == null) {
      return null;
    }

    final parts = <String>[];
    if (song.moderatedBy.trim().isNotEmpty) {
      parts.add(l10n.adminModeratedByLabel(song.moderatedBy));
    }
    if (song.moderatedAt != null) {
      parts.add(
        l10n.adminModeratedAtLabel(_formatShortDateTime(song.moderatedAt!)),
      );
    }

    return parts.join(' • ');
  }

  String _formatShortDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  List<String> _hideReasonPresets(AppLocalizations l10n) {
    return [
      l10n.adminModerationPresetMetadata,
      l10n.adminModerationPresetQuality,
      l10n.adminModerationPresetDuplicate,
    ];
  }

  List<String> _archiveReasonPresets(AppLocalizations l10n) {
    return [
      l10n.adminModerationPresetArchivedReview,
      l10n.adminModerationPresetOutdated,
      l10n.adminModerationPresetDuplicate,
    ];
  }

  void _toggleSongSelection(String songId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedSongIds.add(songId);
      } else {
        _selectedSongIds.remove(songId);
      }
    });
  }

  void _toggleVisibleSelection(List<SongEntity> songs) {
    final visibleSongIds = songs.map((song) => song.id).toSet();
    final allVisibleSelected = visibleSongIds.every(_selectedSongIds.contains);

    setState(() {
      if (allVisibleSelected) {
        _selectedSongIds.removeWhere(visibleSongIds.contains);
      } else {
        _selectedSongIds.addAll(visibleSongIds);
      }
    });
  }

  void _openCreateSongForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminSongFormScreen()),
    );
  }
}

enum _AdminSongAction { publish, hide, archive, restore }

enum _AdminSongSortOption { updatedDesc, updatedAsc, titleAsc }

class _SongStatusBadge extends StatelessWidget {
  const _SongStatusBadge({required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, backgroundColor, foregroundColor) = switch (song.status) {
      SongStatuses.pending => (
        l10n.songStatusPending,
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
      ),
      SongStatuses.hidden => (
        l10n.songStatusHidden,
        const Color(0xFFFFF3CD),
        const Color(0xFF9A6700),
      ),
      SongStatuses.archived => (
        l10n.songStatusArchived,
        const Color(0xFFF3F4F6),
        const Color(0xFF4B5563),
      ),
      _ => (
        l10n.songStatusPublished,
        const Color(0xFFDCFCE7),
        const Color(0xFF166534),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmbeddedAdminHeader extends StatelessWidget {
  const _EmbeddedAdminHeader({
    required this.title,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onRefresh,
    required this.onPrimaryAction,
  });

  final String title;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final VoidCallback onRefresh;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1C24),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(AppLocalizations.of(context)!.retry),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onPrimaryAction,
          icon: Icon(primaryActionIcon),
          label: Text(primaryActionLabel),
        ),
      ],
    );
  }
}
