import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/discover_songs_pagination_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';

const _feedBlack = Color(0xFF000000);
const _feedAccent = Color(0xFFFF6A00);

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.97);
  int _currentIndex = 0;
  String? _lastAutoPlayedSongId;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _activateSong(List<SongEntity> songs, int index) {
    if (songs.isEmpty || index < 0 || index >= songs.length) {
      return;
    }

    final song = songs[index];
    _precacheNearbyImages(songs, index);

    if (_lastAutoPlayedSongId == song.id) {
      return;
    }

    _lastAutoPlayedSongId = song.id;
    unawaited(
      ref
          .read(audioPlayerNotifierProvider.notifier)
          .playSong(song, playlist: [song], loopSingle: true),
    );
  }

  void _precacheNearbyImages(List<SongEntity> songs, int index) {
    for (final nextIndex in [index - 1, index, index + 1]) {
      if (nextIndex < 0 || nextIndex >= songs.length) {
        continue;
      }

      final imageUrl = songs[nextIndex].imageUrl;
      if (imageUrl.isEmpty) {
        continue;
      }

      unawaited(precacheImage(NetworkImage(imageUrl), context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(discoverSongsPaginationProvider);
    final trendingSongs = ref.watch(adminWeeklyTrendingProvider).valueOrNull;
    final statsBySongId = {
      for (final item in trendingSongs ?? const <TrendingSongEntity>[])
        item.song.id: item,
    };

    if (feedState.isInitialLoading && feedState.songs.isEmpty) {
      return const _FeedLoadingView();
    }

    if (feedState.hasInitialError) {
      return _FeedMessageView(
        icon: Icons.error_outline,
        title: 'Cannot load feed',
        subtitle: feedState.initialErrorMessage!,
        actionLabel: 'Retry',
        onAction: () =>
            ref.read(discoverSongsPaginationProvider.notifier).refresh(),
      );
    }

    if (feedState.isEmpty) {
      return _FeedMessageView(
        icon: Icons.dynamic_feed_outlined,
        title: 'Feed is empty',
        subtitle: 'Published songs will appear here.',
        actionLabel: 'Refresh',
        onAction: () =>
            ref.read(discoverSongsPaginationProvider.notifier).refresh(),
      );
    }

    final songs = feedState.songs;
    final currentIndex = _currentIndex.clamp(0, songs.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _activateSong(songs, currentIndex);
      }
    });

    return ColoredBox(
      color: _feedBlack,
      child: SafeArea(
        bottom: false,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const PageScrollPhysics(),
          itemCount: songs.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            _activateSong(songs, index);

            if (index >= songs.length - 3 && feedState.hasMore) {
              ref.read(discoverSongsPaginationProvider.notifier).loadMore();
            }
          },
          itemBuilder: (context, index) {
            final song = songs[index];
            return _FeedSongPage(
              controller: _pageController,
              pageIndex: index,
              currentIndex: currentIndex,
              song: song,
              stats: statsBySongId[song.id],
            );
          },
        ),
      ),
    );
  }
}

class _FeedSongPage extends ConsumerWidget {
  const _FeedSongPage({
    required this.controller,
    required this.pageIndex,
    required this.currentIndex,
    required this.song,
    required this.stats,
  });

  final PageController controller;
  final int pageIndex;
  final int currentIndex;
  final SongEntity song;
  final TrendingSongEntity? stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioPlaybackForSongProvider(song.id));
    final isFavorite = ref.watch(isFavoriteSongProvider(song.id));
    final isFavoriteBusy = ref.watch(isFavoriteSongBusyProvider(song.id));
    final screenWidth = MediaQuery.sizeOf(context).width;
    final outerPadding = screenWidth >= 700 ? 28.0 : 12.0;
    final innerPadding = screenWidth >= 700 ? 24.0 : 16.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final page = _readPageOffset(controller, currentIndex);
        final distance = (page - pageIndex).abs().clamp(0.0, 1.0);
        final scale = 1.06 - (distance * 0.035);
        final opacity = 1.0 - (distance * 0.45);
        final offsetY = (pageIndex - page) * 26;

        return Padding(
          padding: EdgeInsets.fromLTRB(outerPadding, 10, outerPadding, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Transform.scale(
                    scale: scale,
                    child: _FeedArtwork(song: song),
                  ),
                ),
                const _FeedScrim(),
                Positioned(
                  top: 16,
                  left: innerPadding,
                  right: innerPadding,
                  child: const _FeedTopBar(),
                ),
                Positioned(
                  right: innerPadding - 6,
                  bottom: 154,
                  child: FadeTransitionLike(
                    opacity: opacity,
                    child: _FeedActions(
                      isFavorite: isFavorite,
                      isFavoriteBusy: isFavoriteBusy,
                      playCount: stats?.totalPlayCount,
                      listenerCount: stats?.uniqueUserCount,
                      onFavorite: () {
                        ref
                            .read(favoriteNotifierProvider.notifier)
                            .toggleFavorite(song);
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: innerPadding,
                  right: innerPadding + 70,
                  bottom: 124,
                  child: FadeTransitionLike(
                    opacity: opacity,
                    child: _FeedPreTitle(song: song),
                  ),
                ),
                Positioned(
                  left: innerPadding,
                  right: innerPadding,
                  bottom: 14,
                  child: FadeTransitionLike(
                    opacity: opacity,
                    child: _FeedMetadata(
                      song: song,
                      isPlaying: playback.isPlaying,
                      isLoading: playback.isLoading,
                      onPlay: () {
                        final player = ref.read(
                          audioPlayerNotifierProvider.notifier,
                        );
                        if (playback.isPlaying) {
                          player.pause();
                        } else if (playback.isCurrentSong) {
                          player.resume();
                        } else {
                          player.playSong(
                            song,
                            playlist: [song],
                            loopSingle: true,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

double _readPageOffset(PageController controller, int fallbackIndex) {
  if (!controller.hasClients || controller.positions.length != 1) {
    return fallbackIndex.toDouble();
  }

  return controller.page ?? fallbackIndex.toDouble();
}

class FadeTransitionLike extends StatelessWidget {
  const FadeTransitionLike({
    super.key,
    required this.opacity,
    required this.child,
  });

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      opacity: opacity,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: 0.98 + (opacity * 0.02),
        child: child,
      ),
    );
  }
}

class _FeedArtwork extends StatelessWidget {
  const _FeedArtwork({required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    if (song.imageUrl.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF101010),
        child: Center(
          child: Icon(Icons.music_note, color: Colors.white24, size: 110),
        ),
      );
    }

    return Image.network(
      song.imageUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) {
        return const ColoredBox(
          color: Color(0xFF101010),
          child: Center(
            child: Icon(Icons.music_note, color: Colors.white24, size: 110),
          ),
        );
      },
    );
  }
}

class _FeedScrim extends StatelessWidget {
  const _FeedScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.03),
            Colors.black.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.62),
          ],
          stops: const [0, 0.32, 0.62, 1],
        ),
      ),
    );
  }
}

class _FeedTopBar extends StatelessWidget {
  const _FeedTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 42),
        const Expanded(child: Center(child: _FeedTabs())),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
        ),
      ],
    );
  }
}

class _FeedTabs extends StatelessWidget {
  const _FeedTabs();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 45,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _FeedTab(label: 'Discover', isActive: true),
            _FeedTab(label: 'Following', isActive: false),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4B4E4F).withValues(alpha: 0.88)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _FeedActions extends StatelessWidget {
  const _FeedActions({
    required this.isFavorite,
    required this.isFavoriteBusy,
    required this.playCount,
    required this.listenerCount,
    required this.onFavorite,
  });

  final bool isFavorite;
  final bool isFavoriteBusy;
  final int? playCount;
  final int? listenerCount;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeedActionButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(playCount),
          color: isFavorite ? _feedAccent : Colors.white,
          isBusy: isFavoriteBusy,
          onTap: onFavorite,
        ),
        const SizedBox(height: 10),
        _FeedActionButton(
          icon: Icons.chat_bubble_outline,
          label: listenerCount == null ? '10' : _formatCount(listenerCount),
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _FeedActionButton(
          icon: Icons.add_box_outlined,
          label: '',
          onTap: () {},
        ),
      ],
    );
  }
}

class _FeedActionButton extends StatefulWidget {
  const _FeedActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.isBusy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isBusy;

  @override
  State<_FeedActionButton> createState() => _FeedActionButtonState();
}

class _FeedActionButtonState extends State<_FeedActionButton> {
  double _scale = 1;

  void _press() {
    if (widget.isBusy) {
      return;
    }

    setState(() => _scale = 0.86);
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) {
        setState(() => _scale = 1);
      }
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _press,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutBack,
        scale: _scale,
        child: Column(
          children: [
            if (widget.isBusy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Colors.white,
                ),
              )
            else
              Icon(widget.icon, color: widget.color, size: 26),
            if (widget.label.isNotEmpty) ...[
              const SizedBox(height: 2),
              SizedBox(
                width: 42,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedPreTitle extends StatelessWidget {
  const _FeedPreTitle({required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    return Text(
      'liked ${song.title}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: 0,
      ),
    );
  }
}

class _FeedMetadata extends StatelessWidget {
  const _FeedMetadata({
    required this.song,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlay,
  });

  final SongEntity song;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleSize = screenWidth >= 700 ? 28.0 : 20.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        song.title,
                        key: ValueKey(song.id),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ArtistAvatar(song: song),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Follow',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _PlayButton(
                isPlaying: isPlaying,
                isLoading: isLoading,
                onTap: onPlay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  const _ArtistAvatar({required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      backgroundImage: song.imageUrl.isEmpty
          ? null
          : NetworkImage(song.imageUrl),
      child: song.imageUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.white, size: 16)
          : null,
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  double _scale = 1;

  void _press() {
    setState(() => _scale = 0.92);
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) {
        setState(() => _scale = 1);
      }
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _press,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        scale: _scale,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: widget.isPlaying ? 0.78 : 0.22,
                  strokeWidth: 2.6,
                  backgroundColor: Colors.white.withValues(alpha: 0.34),
                  color: _feedAccent,
                ),
              ),
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    color: Colors.black.withValues(alpha: 0.20),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            widget.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedLoadingView extends StatelessWidget {
  const _FeedLoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _feedBlack,
      child: Center(child: CircularProgressIndicator(color: _feedAccent)),
    );
  }
}

class _FeedMessageView extends StatelessWidget {
  const _FeedMessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _feedBlack,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: Colors.white38),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _feedAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCount(int? value) {
  if (value == null || value <= 0) {
    return '0';
  }

  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }

  return value.toString();
}
