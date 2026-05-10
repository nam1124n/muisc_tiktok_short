import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/discover_songs_pagination_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/discover_songs_pagination_state.dart';

class SuggestionsTab extends ConsumerStatefulWidget {
  const SuggestionsTab({super.key});

  @override
  ConsumerState<SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends ConsumerState<SuggestionsTab> {
  static const double _loadMoreThreshold = 320;

  static const List<List<Color>> _trendingPalettes = [
    [Color(0xFF0F172A), Color(0xFF8C52FF), Color(0xFFF43F5E)],
    [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
    [Color(0xFF1F2937), Color(0xFF0EA5E9)],
    [Color(0xFF14532D), Color(0xFF10B981)],
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen<DiscoverSongsPaginationState>(discoverSongsPaginationProvider, (
      previous,
      next,
    ) {
      final message = next.loadMoreErrorMessage;
      if (!mounted ||
          message == null ||
          message == previous?.loadMoreErrorMessage) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: l10n.retry,
            onPressed: () {
              ref
                  .read(discoverSongsPaginationProvider.notifier)
                  .retryLoadMore();
            },
          ),
        ),
      );
    });

    final state = ref.watch(discoverSongsPaginationProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.vertical) {
          return false;
        }

        final shouldLoadMore =
            notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - _loadMoreThreshold;
        if (shouldLoadMore) {
          ref.read(discoverSongsPaginationProvider.notifier).loadMore();
        }
        return false;
      },
      child: _buildContent(context, ref, state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DiscoverSongsPaginationState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final songs = state.songs;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              l10n.trendingTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildTrendingSection(ref)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.forYouTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  l10n.fromFirestore,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8C52FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.hasInitialError)
          SliverToBoxAdapter(
            child: _buildInitialErrorState(
              context,
              message: state.initialErrorMessage!,
            ),
          )
        else if (state.isInitialLoading && songs.isEmpty)
          _buildLoadingSkeletonSliver()
        else if (songs.isEmpty)
          SliverToBoxAdapter(child: _buildEmptyState())
        else
          _buildForYouList(songs),
        SliverToBoxAdapter(child: _buildFooter(context, state)),
      ],
    );
  }

  Widget _buildTrendingSection(WidgetRef ref) {
    final getWeeklyTrendingSongsUseCase = ref.watch(
      getWeeklyTrendingSongsUseCaseProvider,
    );

    return StreamBuilder<List<TrendingSongEntity>>(
      stream: getWeeklyTrendingSongsUseCase(limit: 4),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8C52FF)),
            ),
          );
        }

        final trendingSongs = snapshot.data ?? const <TrendingSongEntity>[];

        if (trendingSongs.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  size: 32,
                  color: Color(0xFF8C52FF),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.trendingEmptyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.trendingEmptySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trendingSongs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final trendingSong = trendingSongs[index];
              final colors =
                  _trendingPalettes[index % _trendingPalettes.length];

              return _buildTrendingCard(
                context: context,
                trendingSong: trendingSong,
                colors: colors,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrendingCard({
    required BuildContext context,
    required TrendingSongEntity trendingSong,
    required List<Color> colors,
  }) {
    final song = trendingSong.song;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (song.imageUrl.isNotEmpty)
            Image.network(
              song.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrendingStats(context, trendingSong),
                const Spacer(),
                Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingStats(
    BuildContext context,
    TrendingSongEntity trendingSong,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatChip(
          icon: Icons.people_alt_outlined,
          label: l10n.listenersCount(
            _formatCount(trendingSong.uniqueUserCount),
          ),
        ),
        _buildStatChip(
          icon: Icons.headphones_outlined,
          label: l10n.playsCount(_formatCount(trendingSong.totalPlayCount)),
        ),
      ],
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }

    return value.toString();
  }

  Widget _buildForYouList(List<SongEntity> songs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const SizedBox(height: 12);
          }

          final songIndex = index ~/ 2;
          final song = songs[songIndex];
          final cardColor =
              _trendingPalettes[songIndex % _trendingPalettes.length].first;

          return Consumer(
            builder: (context, ref, _) {
              final isFavorite = ref.watch(isFavoriteSongProvider(song.id));
              final isFavoriteBusy = ref.watch(
                isFavoriteSongBusyProvider(song.id),
              );
              final playback = ref.watch(audioPlaybackForSongProvider(song.id));
              final isCurrentSong = playback.isCurrentSong;
              final isPlayingThisSong = playback.isPlaying;
              final isLoadingThisSong = playback.isLoading;

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
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${songIndex + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.firestoreAudioLabel,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
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
                                  .toggleFavorite(song);
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
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
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
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
                          ref
                              .read(audioPlayerNotifierProvider.notifier)
                              .pause();
                        } else if (isCurrentSong) {
                          ref
                              .read(audioPlayerNotifierProvider.notifier)
                              .resume();
                        } else {
                          ref
                              .read(audioPlayerNotifierProvider.notifier)
                              .playSong(song, playlist: songs);
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
        }, childCount: songs.isEmpty ? 0 : songs.length * 2 - 1),
      ),
    );
  }

  Widget _buildLoadingSkeletonSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const SizedBox(height: 12);
          }

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 10,
                        width: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }, childCount: 11),
      ),
    );
  }

  Widget _buildInitialErrorState(
    BuildContext context, {
    required String message,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref
                    .read(discoverSongsPaginationProvider.notifier)
                    .loadInitial();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    DiscoverSongsPaginationState state,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFF8C52FF),
            ),
          ),
        ),
      );
    }

    if (state.loadMoreErrorMessage != null && state.songs.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () {
              ref
                  .read(discoverSongsPaginationProvider.notifier)
                  .retryLoadMore();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ),
      );
    }

    if (!state.hasMore && state.songs.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Center(
          child: Text(
            'Bạn đã xem hết danh sách.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.library_music_outlined,
                    size: 56,
                    color: Color(0xFF8C52FF),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.noSongDataTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noSongDataSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
