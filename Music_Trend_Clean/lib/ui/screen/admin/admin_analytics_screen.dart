import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_state.dart';
import 'package:login_flutter/ui/screen/genre/providers/year_song_provider.dart';

const _allAnalyticsStatusFilter = 'all';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = _allAnalyticsStatusFilter;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAdminAccess = ref.watch(sessionHasAdminAccessProvider);
    final songState = ref.watch(adminSongNotifierProvider);
    final yearSongState = ref.watch(yearSongNotifierProvider);
    final trendingAsync = ref.watch(adminWeeklyTrendingProvider);

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
          ],
        ),
      );
    }

    if (songState is SongLoading || yearSongState is SongLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8C52FF)),
      );
    }

    if (songState is SongError) {
      return _AnalyticsLoadError(
        message: songState.message,
        onRetry: () => ref.read(adminSongNotifierProvider.notifier).loadSongs(),
      );
    }

    if (yearSongState is SongError) {
      return _AnalyticsLoadError(
        message: yearSongState.message,
        onRetry: () => ref.read(yearSongNotifierProvider.notifier).loadSongs(),
      );
    }

    final songs = songState is SongLoaded
        ? songState.songs
        : const <SongEntity>[];
    final yearSongs = yearSongState is SongLoaded
        ? yearSongState.songs
        : const <SongEntity>[];

    final filteredSongs = _applyAnalyticsFilters(songs);
    final filteredYearSongs = _applyAnalyticsFilters(yearSongs);
    final overview = _AdminAnalyticsOverview.fromSongs(filteredSongs);
    final pendingOldestSongs = _pendingOldest(filteredSongs);
    final recentlyUpdatedSongs = _recentlyUpdated(filteredSongs);
    final recentlyUpdatedYearSongs = _recentlyUpdated(filteredYearSongs);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.adminAnalyticsOverviewTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1C24),
            ),
          ),
          const SizedBox(height: 16),
          _buildControlsCard(context),
          const SizedBox(height: 16),
          _buildOverviewCards(context, overview),
          const SizedBox(height: 28),
          _buildInsightsGrid(
            context,
            recentlyUpdatedSongs: recentlyUpdatedSongs,
            pendingOldestSongs: pendingOldestSongs,
            recentlyUpdatedYearSongs: recentlyUpdatedYearSongs,
          ),
          const SizedBox(height: 28),
          Text(
            l10n.adminWeeklyTrendingTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1C24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.adminWeeklyTrendingSubtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          trendingAsync.when(
            data: (songs) =>
                _TrendingPanel(trendingSongs: _filterTrendingSongs(songs)),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: Color(0xFF8C52FF)),
              ),
            ),
            error: (error, _) => _AnalyticsErrorCard(message: error.toString()),
          ),
          const SizedBox(height: 16),
          _InfoNoteCard(
            title: l10n.adminYearSongsAnalyticsTitle,
            message: l10n.adminYearSongsAnalyticsSubtitle,
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusOptions = [
      (_allAnalyticsStatusFilter, l10n.adminFilterAll),
      (SongStatuses.published, l10n.adminFilterPublished),
      (SongStatuses.pending, l10n.adminFilterPending),
      (SongStatuses.hidden, l10n.adminFilterHidden),
      (SongStatuses.archived, l10n.adminFilterArchived),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminAnalyticsControlsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.adminSearchHint,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in statusOptions) ...[
                  ChoiceChip(
                    label: Text(label),
                    selected: _selectedStatusFilter == value,
                    onSelected: (_) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(
    BuildContext context,
    _AdminAnalyticsOverview overview,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1200;
        final isMedium = constraints.maxWidth >= 820;
        final columns = isWide ? 5 : (isMedium ? 3 : 1);
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        final cards = [
          _OverviewCardData(
            label: l10n.adminTotalSongsLabel,
            value: overview.totalSongs,
            icon: Icons.library_music_outlined,
            colors: const [Color(0xFF5B8CFF), Color(0xFF8EC5FF)],
          ),
          _OverviewCardData(
            label: l10n.adminPublishedSongsLabel,
            value: overview.publishedSongs,
            icon: Icons.check_circle_outline_rounded,
            colors: const [Color(0xFF17B26A), Color(0xFF6CE9A6)],
          ),
          _OverviewCardData(
            label: l10n.adminPendingSongsLabel,
            value: overview.pendingSongs,
            icon: Icons.schedule_outlined,
            colors: const [Color(0xFFF59E0B), Color(0xFFFCD34D)],
          ),
          _OverviewCardData(
            label: l10n.adminHiddenSongsLabel,
            value: overview.hiddenSongs,
            icon: Icons.visibility_off_outlined,
            colors: const [Color(0xFF7C3AED), Color(0xFFC4B5FD)],
          ),
          _OverviewCardData(
            label: l10n.adminArchivedSongsLabel,
            value: overview.archivedSongs,
            icon: Icons.archive_outlined,
            colors: const [Color(0xFF6B7280), Color(0xFFD1D5DB)],
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: columns == 1 ? constraints.maxWidth : cardWidth,
                child: _OverviewMetricCard(data: card),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInsightsGrid(
    BuildContext context, {
    required List<SongEntity> recentlyUpdatedSongs,
    required List<SongEntity> pendingOldestSongs,
    required List<SongEntity> recentlyUpdatedYearSongs,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;
        final firstRow = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SongInsightPanel(
                      title: l10n.adminRecentlyUpdatedTitle,
                      subtitle: l10n.adminRecentlyUpdatedSubtitle,
                      songs: recentlyUpdatedSongs,
                      emptyMessage: l10n.adminNoRecentlyUpdatedMessage,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SongInsightPanel(
                      title: l10n.adminPendingOldestTitle,
                      subtitle: l10n.adminPendingOldestSubtitle,
                      songs: pendingOldestSongs,
                      emptyMessage: l10n.adminNoPendingOldestMessage,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _SongInsightPanel(
                    title: l10n.adminRecentlyUpdatedTitle,
                    subtitle: l10n.adminRecentlyUpdatedSubtitle,
                    songs: recentlyUpdatedSongs,
                    emptyMessage: l10n.adminNoRecentlyUpdatedMessage,
                  ),
                  const SizedBox(height: 16),
                  _SongInsightPanel(
                    title: l10n.adminPendingOldestTitle,
                    subtitle: l10n.adminPendingOldestSubtitle,
                    songs: pendingOldestSongs,
                    emptyMessage: l10n.adminNoPendingOldestMessage,
                  ),
                ],
              );

        return Column(
          children: [
            firstRow,
            const SizedBox(height: 16),
            _SongInsightPanel(
              title: l10n.adminYearSongsRecentlyUpdatedTitle,
              subtitle: l10n.adminYearSongsRecentlyUpdatedSubtitle,
              songs: recentlyUpdatedYearSongs,
              emptyMessage: l10n.adminNoYearSongsRecentlyUpdatedMessage,
            ),
          ],
        );
      },
    );
  }

  List<SongEntity> _applyAnalyticsFilters(List<SongEntity> songs) {
    final statusFiltered = _selectedStatusFilter == _allAnalyticsStatusFilter
        ? songs
        : songs.where((song) => song.status == _selectedStatusFilter).toList();
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return statusFiltered;
    }

    return statusFiltered.where((song) {
      final haystack = <String>[
        song.title,
        song.artist,
        song.status,
        song.moderationReason,
        song.savedAt?.year.toString() ?? '',
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  List<TrendingSongEntity> _filterTrendingSongs(
    List<TrendingSongEntity> songs,
  ) {
    final filtered = _applyAnalyticsFilters(
      songs.map((item) => item.song).toList(),
    );
    final filteredIds = filtered.map((song) => song.id).toSet();
    return songs.where((item) => filteredIds.contains(item.song.id)).toList();
  }

  List<SongEntity> _recentlyUpdated(List<SongEntity> songs) {
    final sortedSongs = List<SongEntity>.from(songs);
    sortedSongs.sort(
      (left, right) => _songTimestamp(right).compareTo(_songTimestamp(left)),
    );
    return sortedSongs.take(5).toList();
  }

  List<SongEntity> _pendingOldest(List<SongEntity> songs) {
    final pendingSongs = songs.where((song) => song.isPending).toList();
    pendingSongs.sort(
      (left, right) => _songTimestamp(left).compareTo(_songTimestamp(right)),
    );
    return pendingSongs.take(5).toList();
  }

  DateTime _songTimestamp(SongEntity song) {
    return song.updatedAt ??
        song.savedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _AnalyticsLoadError extends StatelessWidget {
  const _AnalyticsLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

class _AdminAnalyticsOverview {
  const _AdminAnalyticsOverview({
    required this.totalSongs,
    required this.publishedSongs,
    required this.pendingSongs,
    required this.hiddenSongs,
    required this.archivedSongs,
  });

  final int totalSongs;
  final int publishedSongs;
  final int pendingSongs;
  final int hiddenSongs;
  final int archivedSongs;

  factory _AdminAnalyticsOverview.fromSongs(List<SongEntity> songs) {
    var publishedSongs = 0;
    var pendingSongs = 0;
    var hiddenSongs = 0;
    var archivedSongs = 0;

    for (final song in songs) {
      if (song.isPublished) {
        publishedSongs++;
      } else if (song.isPending) {
        pendingSongs++;
      } else if (song.isHidden) {
        hiddenSongs++;
      } else if (song.isArchived) {
        archivedSongs++;
      }
    }

    return _AdminAnalyticsOverview(
      totalSongs: songs.length,
      publishedSongs: publishedSongs,
      pendingSongs: pendingSongs,
      hiddenSongs: hiddenSongs,
      archivedSongs: archivedSongs,
    );
  }
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
  });

  final String label;
  final int value;
  final IconData icon;
  final List<Color> colors;
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({required this.data});

  final _OverviewCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: data.colors.first.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: Colors.white, size: 26),
          const SizedBox(height: 24),
          Text(
            '${data.value}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SongInsightPanel extends StatelessWidget {
  const _SongInsightPanel({
    required this.title,
    required this.subtitle,
    required this.songs,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final List<SongEntity> songs;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          if (songs.isEmpty)
            Text(emptyMessage, style: TextStyle(color: Colors.grey[600]))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: songs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final song = songs[index];
                final timestamp = song.updatedAt ?? song.savedAt;
                final statusLabel = _statusLabel(context, song);
                final subtitleParts = <String>[
                  song.artist,
                  if (song.savedAt != null) '${song.savedAt!.year}',
                  statusLabel,
                  if (timestamp != null) _formatDate(timestamp),
                ];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleParts.join(' • '),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (song.moderationReason.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          song.moderationReason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9A6700),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, SongEntity song) {
    final l10n = AppLocalizations.of(context)!;
    return switch (song.status) {
      SongStatuses.pending => l10n.songStatusPending,
      SongStatuses.hidden => l10n.songStatusHidden,
      SongStatuses.archived => l10n.songStatusArchived,
      _ => l10n.songStatusPublished,
    };
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _TrendingPanel extends StatelessWidget {
  const _TrendingPanel({required this.trendingSongs});

  final List<TrendingSongEntity> trendingSongs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (trendingSongs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: Color(0xFF8C52FF),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.trendingEmptyTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trendingEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: trendingSongs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final trendingSong = trendingSongs[index];
          final song = trendingSong.song;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C52FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF8C52FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.listenersCount(
                        trendingSong.uniqueUserCount.toString(),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.playsCount(trendingSong.totalPlayCount.toString()),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoNoteCard extends StatelessWidget {
  const _InfoNoteCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD97706)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9A6700),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Color(0xFF9A6700), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsErrorCard extends StatelessWidget {
  const _AnalyticsErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
