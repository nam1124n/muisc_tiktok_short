import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/domain/entities/playlist_entity.dart';
import 'package:login_flutter/domain/entities/feed_comment_entity.dart';
import 'package:login_flutter/domain/entities/song_entity.dart';
import 'package:login_flutter/domain/entities/trending_song_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/auth/login_screen.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/feed/feed_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/playlist_provider.dart';
import 'package:share_plus/share_plus.dart';

const _feedBlack = Color(0xFF000000);
const _feedAccent = Color(0xFFFF6A00);

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

Future<bool> _ensureSignedIn(
  BuildContext context,
  WidgetRef ref, {
  required String message,
}) async {
  if (ref.read(sessionProvider).isAuthenticated) {
    return true;
  }

  final l10n = AppLocalizations.of(context)!;
  final shouldLogin = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
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
              const Icon(
                Icons.lock_outline_rounded,
                color: _feedAccent,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.profileSignInRequiredTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF151515),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.62),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _feedAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.login),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (shouldLogin != true || !context.mounted) {
    return false;
  }

  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));

  if (!context.mounted) {
    return false;
  }

  return ref.read(sessionProvider).isAuthenticated;
}

Future<void> _toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  SongEntity song,
) async {
  final canContinue = await _ensureSignedIn(
    context,
    ref,
    message: AppLocalizations.of(context)!.feedSignInLikeMessage,
  );
  if (!canContinue) {
    return;
  }

  final wasFavorite = ref.read(isFavoriteSongProvider(song.id));
  await ref.read(favoriteNotifierProvider.notifier).toggleFavorite(song);
  final isFavorite = ref.read(isFavoriteSongProvider(song.id));
  if (wasFavorite != isFavorite) {
    ref
        .read(feedProvider.notifier)
        .applyFavoriteDelta(song.id, isFavorite ? 1 : -1);
  }
}

Future<void> _showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  SongEntity song,
) async {
  final canContinue = await _ensureSignedIn(
    context,
    ref,
    message: AppLocalizations.of(context)!.feedSignInPlaylistMessage,
  );
  if (!canContinue || !context.mounted) {
    return;
  }

  unawaited(ref.read(playlistNotifierProvider.notifier).loadPlaylists());

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddToPlaylistSheet(song: song),
  );
}

Future<void> _shareSong(SongEntity song) async {
  final title = song.artist.trim().isEmpty
      ? song.title.trim()
      : '${song.title.trim()} - ${song.artist.trim()}';
  final audioUrl = song.audioUrl.trim();
  final text = audioUrl.isEmpty ? title : '$title\n$audioUrl';

  await SharePlus.instance.share(ShareParams(text: text));
}

Future<void> _showCommentSheet(
  BuildContext context,
  WidgetRef ref,
  SongEntity song,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeedCommentSheet(song: song),
  );
}

Future<void> _showFeedMoreMenu(
  BuildContext context,
  WidgetRef ref,
  SongEntity song,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _FeedMoreSheet(
        song: song,
        onShare: () {
          Navigator.of(sheetContext).pop();
          unawaited(_shareSong(song));
        },
        onAddPlaylist: () {
          Navigator.of(sheetContext).pop();
          unawaited(_showAddToPlaylistSheet(context, ref, song));
        },
        onReport: () {
          Navigator.of(sheetContext).pop();
          unawaited(_showReportDialog(context, ref, song));
        },
        onHide: () {
          Navigator.of(sheetContext).pop();
          unawaited(ref.read(feedProvider.notifier).hideSong(song));
          final currentSong = ref.read(audioPlayerNotifierProvider).currentSong;
          if (currentSong?.id == song.id) {
            ref.read(audioPlayerNotifierProvider.notifier).pause();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.feedHiddenMessage),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showReportDialog(
  BuildContext context,
  WidgetRef ref,
  SongEntity song,
) async {
  final canContinue = await _ensureSignedIn(
    context,
    ref,
    message: AppLocalizations.of(context)!.feedSignInReportMessage,
  );
  if (!canContinue || !context.mounted) {
    return;
  }

  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final submitted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          l10n.feedReportTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.feedReportDetailsLabel,
                hintText: l10n.feedReportDetailsHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(l10n.feedSubmitAction),
          ),
        ],
      );
    },
  );
  final reason = controller.text.trim();
  controller.dispose();

  if (submitted == true && context.mounted) {
    final success = await ref
        .read(feedProvider.notifier)
        .submitReport(song: song, reason: reason);
    if (!context.mounted) {
      return;
    }

    final errorMessage = ref.read(feedProvider).actionErrorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.feedReportSubmittedMessage
              : errorMessage ?? l10n.feedReportFailedMessage,
        ),
        backgroundColor: success ? null : Colors.red,
      ),
    );
  }
}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 0.97);
  int _currentIndex = 0;
  String? _lastAutoPlayedSongId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseCurrentFeedSong();
    }
  }

  void _pauseCurrentFeedSong() {
    final currentSong = ref.read(audioPlayerNotifierProvider).currentSong;
    if (currentSong == null) {
      return;
    }

    final isFeedSong = ref
        .read(feedProvider)
        .songs
        .any((song) => song.id == currentSong.id);
    if (isFeedSong) {
      ref.read(audioPlayerNotifierProvider.notifier).pause();
    }
  }

  void _selectTab(FeedTabType tab) {
    if (tab == ref.read(feedProvider).selectedTab) {
      return;
    }

    _pauseCurrentFeedSong();
    _lastAutoPlayedSongId = null;
    setState(() => _currentIndex = 0);
    ref.read(feedProvider.notifier).selectTab(tab);

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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
          .playSong(song, playlist: songs, loopSingle: false),
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
    final feedState = ref.watch(feedProvider);
    final trendingSongs = ref.watch(adminWeeklyTrendingProvider).valueOrNull;
    final statsBySongId = {
      for (final item in trendingSongs ?? const <TrendingSongEntity>[])
        item.song.id: item,
    };

    if (feedState.isInitialLoading && feedState.songs.isEmpty) {
      return const _FeedLoadingView();
    }

    if (feedState.hasInitialError) {
      final l10n = AppLocalizations.of(context)!;
      return _FeedMessageView(
        icon: Icons.error_outline,
        title: l10n.feedCannotLoadTitle,
        subtitle: feedState.initialErrorMessage!,
        actionLabel: l10n.feedRetryAction,
        onAction: () => ref.read(feedProvider.notifier).refresh(),
      );
    }

    if (feedState.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final isFollowing = feedState.selectedTab == FeedTabType.following;
      return _FeedMessageView(
        icon: Icons.dynamic_feed_outlined,
        title: isFollowing ? l10n.feedFollowingEmptyTitle : l10n.feedEmptyTitle,
        subtitle: isFollowing
            ? l10n.feedFollowingEmptySubtitle
            : l10n.feedEmptySubtitle,
        actionLabel: isFollowing
            ? l10n.feedDiscoverTab
            : l10n.feedRefreshAction,
        onAction: isFollowing
            ? () => _selectTab(FeedTabType.discover)
            : () => ref.read(feedProvider.notifier).refresh(),
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
        child: RefreshIndicator(
          color: _feedAccent,
          backgroundColor: const Color(0xFF151515),
          onRefresh: () => ref.read(feedProvider.notifier).refresh(),
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const PageScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: songs.length + (feedState.hasMore ? 1 : 0),
            onPageChanged: (index) {
              if (index < songs.length) {
                setState(() => _currentIndex = index);
                _activateSong(songs, index);
              }

              if (index >= songs.length - 3 && feedState.hasMore) {
                ref.read(feedProvider.notifier).loadMore();
              }
            },
            itemBuilder: (context, index) {
              if (index >= songs.length) {
                return _FeedFooterPage(
                  isLoading: feedState.isLoadingMore,
                  message: feedState.loadMoreErrorMessage,
                  onRetry: () =>
                      ref.read(feedProvider.notifier).retryLoadMore(),
                );
              }

              final song = songs[index];
              return _FeedSongPage(
                controller: _pageController,
                pageIndex: index,
                currentIndex: currentIndex,
                song: song,
                stats: statsBySongId[song.id],
                selectedTab: feedState.selectedTab,
                onTabSelected: _selectTab,
              );
            },
          ),
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
    required this.selectedTab,
    required this.onTabSelected,
  });

  final PageController controller;
  final int pageIndex;
  final int currentIndex;
  final SongEntity song;
  final TrendingSongEntity? stats;
  final FeedTabType selectedTab;
  final ValueChanged<FeedTabType> onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioPlaybackForSongProvider(song.id));
    final isFavorite = ref.watch(isFavoriteSongProvider(song.id));
    final isFavoriteBusy = ref.watch(isFavoriteSongBusyProvider(song.id));
    final feedState = ref.watch(feedProvider);
    final favoriteCount = feedState.favoriteCountFor(song);
    final commentCount = feedState.commentCountFor(song);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final outerPadding = screenWidth >= 700 ? 28.0 : 12.0;
    final innerPadding = screenWidth >= 700 ? 24.0 : 16.0;

    void togglePlayback() {
      final player = ref.read(audioPlayerNotifierProvider.notifier);
      if (playback.isPlaying) {
        player.pause();
      } else if (playback.isCurrentSong) {
        player.resume();
      } else {
        player.playSong(song, playlist: [song], loopSingle: true);
      }
    }

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
                Positioned.fill(
                  child: _FeedArtworkGestureLayer(
                    isPlaying: playback.isPlaying,
                    isLoading: playback.isLoading,
                    onTap: togglePlayback,
                    onDoubleTap: () {
                      unawaited(_toggleFavorite(context, ref, song));
                    },
                  ),
                ),
                Positioned(
                  top: 16,
                  left: innerPadding,
                  right: innerPadding,
                  child: _FeedTopBar(
                    selectedTab: selectedTab,
                    onTabSelected: onTabSelected,
                    onMore: () => _showFeedMoreMenu(context, ref, song),
                  ),
                ),
                Positioned(
                  right: innerPadding - 6,
                  bottom: 154,
                  child: FadeTransitionLike(
                    opacity: opacity,
                    child: _FeedActions(
                      isFavorite: isFavorite,
                      isFavoriteBusy: isFavoriteBusy,
                      favoriteCount: favoriteCount,
                      commentCount: commentCount,
                      onFavorite: () {
                        unawaited(_toggleFavorite(context, ref, song));
                      },
                      onComment: () {
                        unawaited(_showCommentSheet(context, ref, song));
                      },
                      onAddPlaylist: () {
                        unawaited(_showAddToPlaylistSheet(context, ref, song));
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
                    child: _FeedPreTitle(
                      playCount: stats?.totalPlayCount ?? song.totalPlayCount,
                    ),
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
                      onPlay: togglePlayback,
                      progress: playback.progress,
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

class _FeedArtworkGestureLayer extends StatefulWidget {
  const _FeedArtworkGestureLayer({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
    required this.onDoubleTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  State<_FeedArtworkGestureLayer> createState() =>
      _FeedArtworkGestureLayerState();
}

class _FeedArtworkGestureLayerState extends State<_FeedArtworkGestureLayer> {
  bool _showTapFeedback = false;
  bool _showHeart = false;

  void _showTransientTapFeedback() {
    setState(() => _showTapFeedback = true);
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (mounted) {
        setState(() => _showTapFeedback = false);
      }
    });
  }

  void _showTransientHeart() {
    setState(() => _showHeart = true);
    Future<void>.delayed(const Duration(milliseconds: 680), () {
      if (mounted) {
        setState(() => _showHeart = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showPreviewPrompt = !widget.isPlaying && !widget.isLoading;
    final showOverlay = showPreviewPrompt || _showTapFeedback;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.onTap();
        _showTransientTapFeedback();
      },
      onDoubleTap: () {
        widget.onDoubleTap();
        _showTransientHeart();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              opacity: showOverlay ? 1 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: showPreviewPrompt ? 0.28 : 0.16,
                  ),
                ),
                child: Center(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    scale: showOverlay ? 1 : 0.9,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          showPreviewPrompt
                              ? AppLocalizations.of(context)!.feedTapToPreview
                              : widget.isPlaying
                              ? AppLocalizations.of(context)!.feedPauseAction
                              : AppLocalizations.of(context)!.feedPlayAction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              width: 66,
                              height: 66,
                              alignment: Alignment.center,
                              color: Colors.white.withValues(alpha: 0.18),
                              child: Icon(
                                showPreviewPrompt
                                    ? Icons.volume_off_rounded
                                    : widget.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 130),
                curve: Curves.easeOut,
                opacity: _showHeart ? 1 : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: _showHeart ? 1 : 0.42,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: _feedAccent.withValues(alpha: 0.94),
                    size: 104,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
  const _FeedTopBar({
    this.selectedTab = FeedTabType.discover,
    this.onTabSelected,
    this.onMore,
  });

  final FeedTabType selectedTab;
  final ValueChanged<FeedTabType>? onTabSelected;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 42),
        Expanded(
          child: Center(
            child: _FeedTabs(
              selectedTab: selectedTab,
              onTabSelected: onTabSelected,
            ),
          ),
        ),
        IconButton(
          onPressed: onMore,
          icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
        ),
      ],
    );
  }
}

class _FeedTabs extends StatelessWidget {
  const _FeedTabs({required this.selectedTab, required this.onTabSelected});

  final FeedTabType selectedTab;
  final ValueChanged<FeedTabType>? onTabSelected;

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
          children: [
            _FeedTab(
              label: AppLocalizations.of(context)!.feedDiscoverTab,
              isActive: selectedTab == FeedTabType.discover,
              onTap: () => onTabSelected?.call(FeedTabType.discover),
            ),
            _FeedTab(
              label: AppLocalizations.of(context)!.feedFollowingTab,
              isActive: selectedTab == FeedTabType.following,
              onTap: () => onTabSelected?.call(FeedTabType.following),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
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
      ),
    );
  }
}

class _FeedActions extends StatelessWidget {
  const _FeedActions({
    required this.isFavorite,
    required this.isFavoriteBusy,
    required this.favoriteCount,
    required this.commentCount,
    required this.onFavorite,
    required this.onComment,
    required this.onAddPlaylist,
  });

  final bool isFavorite;
  final bool isFavoriteBusy;
  final int favoriteCount;
  final int? commentCount;
  final VoidCallback onFavorite;
  final VoidCallback onComment;
  final VoidCallback onAddPlaylist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeedActionButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(favoriteCount),
          color: isFavorite ? _feedAccent : Colors.white,
          isBusy: isFavoriteBusy,
          onTap: onFavorite,
        ),
        const SizedBox(height: 10),
        _FeedActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(commentCount),
          onTap: onComment,
        ),
        const SizedBox(height: 10),
        _FeedActionButton(
          icon: Icons.add_box_outlined,
          label: '',
          onTap: onAddPlaylist,
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

class _FeedMoreSheet extends StatelessWidget {
  const _FeedMoreSheet({
    required this.song,
    required this.onShare,
    required this.onAddPlaylist,
    required this.onReport,
    required this.onHide,
  });

  final SongEntity song;
  final VoidCallback onShare;
  final VoidCallback onAddPlaylist;
  final VoidCallback onReport;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SheetArtwork(song: song),
                const SizedBox(width: 12),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FeedMoreAction(
              icon: Icons.ios_share_rounded,
              label: l10n.feedShareAction,
              onTap: onShare,
            ),
            _FeedMoreAction(
              icon: Icons.playlist_add_rounded,
              label: l10n.feedAddToPlaylistAction,
              onTap: onAddPlaylist,
            ),
            _FeedMoreAction(
              icon: Icons.flag_outlined,
              label: l10n.feedReportAction,
              onTap: onReport,
            ),
            _FeedMoreAction(
              icon: Icons.visibility_off_outlined,
              label: l10n.feedHideAction,
              isDestructive: true,
              onTap: onHide,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedMoreAction extends StatelessWidget {
  const _FeedMoreAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFFF6B6B) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
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

class _FeedCommentSheet extends ConsumerStatefulWidget {
  const _FeedCommentSheet({required this.song});

  final SongEntity song;

  @override
  ConsumerState<_FeedCommentSheet> createState() => _FeedCommentSheetState();
}

class _FeedCommentSheetState extends ConsumerState<_FeedCommentSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    final canContinue = await _ensureSignedIn(
      context,
      ref,
      message: AppLocalizations.of(context)!.feedSignInCommentMessage,
    );
    if (!canContinue || !mounted) {
      return;
    }

    final success = await ref
        .read(feedProvider.notifier)
        .addComment(song: widget.song, text: text);
    if (!mounted) {
      return;
    }

    if (success) {
      _controller.clear();
      return;
    }

    final errorMessage =
        ref.read(feedProvider).actionErrorMessage ??
        AppLocalizations.of(context)!.feedCommentFailedMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  }

  Future<void> _delete(FeedCommentEntity comment) async {
    final success = await ref
        .read(feedProvider.notifier)
        .deleteComment(comment);
    if (!mounted || success) {
      return;
    }

    final errorMessage =
        ref.read(feedProvider).actionErrorMessage ??
        AppLocalizations.of(context)!.feedDeleteCommentFailedMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(feedCommentsProvider(widget.song.id));
    final l10n = AppLocalizations.of(context)!;
    final isSending = ref.watch(
      feedProvider.select(
        (state) => state.commentingSongIds.contains(widget.song.id),
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.feedCommentsTitle,
                              style: const TextStyle(
                                color: Color(0xFF151515),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.56),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: comments.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 52,
                              color: Colors.black.withValues(alpha: 0.22),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.feedNoCommentsTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF151515),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final comment = items[index];
                          return _FeedCommentTile(
                            comment: comment,
                            onDelete: () => _delete(comment),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: _feedAccent),
                    ),
                    error: (error, _) => ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.black38,
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ErrorMessageMapper.map(error),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    10,
                    14,
                    10 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !isSending,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: l10n.feedAddCommentHint,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: isSending ? null : _send,
                        style: IconButton.styleFrom(
                          backgroundColor: _feedAccent,
                          foregroundColor: Colors.white,
                        ),
                        icon: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
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

class _FeedCommentTile extends ConsumerWidget {
  const _FeedCommentTile({required this.comment, required this.onDelete});

  final FeedCommentEntity comment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(sessionCurrentUserIdProvider);
    final profile = comment.userId.trim().isEmpty
        ? null
        : ref.watch(publicProfileProvider(comment.userId));
    final profileName = profile?.valueOrNull?.username.trim() ?? '';
    final displayName = profileName.isNotEmpty ? profileName : comment.userName;
    final avatarUrl = profile?.valueOrNull?.avatarUrl.trim() ?? '';
    final fallbackName = AppLocalizations.of(context)!.feedListenerFallbackName;
    final canDelete = currentUserId != null && currentUserId == comment.userId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: _feedAccent.withValues(alpha: 0.12),
          backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
          child: avatarUrl.isEmpty
              ? Text(
                  _commentInitial(displayName),
                  style: const TextStyle(
                    color: _feedAccent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName.trim().isEmpty ? fallbackName : displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF151515),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                comment.text,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        if (canDelete)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: Colors.black45,
          ),
      ],
    );
  }
}

class _AddToPlaylistSheet extends ConsumerStatefulWidget {
  const _AddToPlaylistSheet({required this.song});

  final SongEntity song;

  @override
  ConsumerState<_AddToPlaylistSheet> createState() =>
      _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<_AddToPlaylistSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreatingAndAdding = false;
  String? _localErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addToPlaylist(PlaylistEntity playlist) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (playlist.songIds.contains(widget.song.id)) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.feedAlreadyInPlaylistMessage(playlist.name),
          ),
        ),
      );
      return;
    }

    final nextSongIds = [...playlist.songIds, widget.song.id];
    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .savePlaylistSongs(playlistId: playlist.id, songIds: nextSongIds);

    if (!mounted) {
      return;
    }

    final errorMessage = _playlistErrorText(
      context,
      ref.read(playlistNotifierProvider),
    );
    if (!success && errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          )!.feedAddedToPlaylistMessage(playlist.name),
        ),
      ),
    );
  }

  Future<void> _createAndAdd() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty || _isCreatingAndAdding) {
      setState(
        () => _localErrorMessage = AppLocalizations.of(
          context,
        )!.feedEnterPlaylistNameMessage,
      );
      return;
    }

    setState(() {
      _isCreatingAndAdding = true;
      _localErrorMessage = null;
    });

    final previousIds = {
      for (final playlist in ref.read(playlistNotifierProvider).playlists)
        playlist.id,
    };
    final created = await ref
        .read(playlistNotifierProvider.notifier)
        .createPlaylist(name);

    if (!mounted) {
      return;
    }

    if (!created) {
      final errorMessage = _playlistErrorText(
        context,
        ref.read(playlistNotifierProvider),
      );
      setState(() {
        _isCreatingAndAdding = false;
        _localErrorMessage =
            errorMessage ??
            AppLocalizations.of(context)!.feedCreatePlaylistFailedMessage;
      });
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    final playlists = ref.read(playlistNotifierProvider).playlists;
    PlaylistEntity? createdPlaylist;
    for (final playlist in playlists) {
      if (!previousIds.contains(playlist.id)) {
        createdPlaylist = playlist;
        break;
      }
    }

    createdPlaylist ??= playlists.isEmpty ? null : playlists.first;
    if (createdPlaylist == null) {
      setState(() {
        _isCreatingAndAdding = false;
        _localErrorMessage = AppLocalizations.of(
          context,
        )!.feedNewPlaylistNotFoundMessage;
      });
      return;
    }

    final success = await ref
        .read(playlistNotifierProvider.notifier)
        .savePlaylistSongs(
          playlistId: createdPlaylist.id,
          songIds: [widget.song.id],
        );

    if (!mounted) {
      return;
    }

    final errorMessage = _playlistErrorText(
      context,
      ref.read(playlistNotifierProvider),
    );
    if (!success && errorMessage != null) {
      setState(() {
        _isCreatingAndAdding = false;
        _localErrorMessage = errorMessage;
      });
      ref.read(playlistNotifierProvider.notifier).clearError();
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          )!.feedAddedToPlaylistMessage(createdPlaylist.name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final playlistState = ref.watch(playlistNotifierProvider);
    final playlists = playlistState.playlists;
    final isBusy =
        playlistState.isSaving ||
        playlistState.isCreating ||
        _isCreatingAndAdding;
    final errorMessage =
        _localErrorMessage ?? _playlistErrorText(context, playlistState);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.playlistsLabel,
                              style: const TextStyle(
                                color: Color(0xFF151515),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.56),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          enabled: !isBusy,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _createAndAdd(),
                          decoration: InputDecoration(
                            labelText: l10n.playlistNameLabel,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: l10n.createNewPlaylist,
                        child: FilledButton(
                          onPressed: isBusy ? null : _createAndAdd,
                          style: FilledButton.styleFrom(
                            backgroundColor: _feedAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                          child: _isCreatingAndAdding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _PlaylistSheetBody(
                    scrollController: scrollController,
                    playlistState: playlistState,
                    playlists: playlists,
                    isBusy: isBusy,
                    song: widget.song,
                    onRetry: () {
                      ref
                          .read(playlistNotifierProvider.notifier)
                          .loadPlaylists();
                    },
                    onPlaylistTap: _addToPlaylist,
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

class _PlaylistSheetBody extends StatelessWidget {
  const _PlaylistSheetBody({
    required this.scrollController,
    required this.playlistState,
    required this.playlists,
    required this.isBusy,
    required this.song,
    required this.onRetry,
    required this.onPlaylistTap,
  });

  final ScrollController scrollController;
  final PlaylistState playlistState;
  final List<PlaylistEntity> playlists;
  final bool isBusy;
  final SongEntity song;
  final VoidCallback onRetry;
  final ValueChanged<PlaylistEntity> onPlaylistTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (playlistState.isLoading && playlists.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _feedAccent));
    }

    if (playlists.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Icon(
            playlistState.errorMessage == null
                ? Icons.playlist_add_rounded
                : Icons.error_outline_rounded,
            color: Colors.black26,
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            playlistState.errorMessage == null
                ? l10n.playlistEmptyTitle
                : l10n.playlistLoadErrorTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF151515),
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlistState.errorMessage ?? l10n.playlistEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          if (playlistState.errorMessage != null) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
      itemCount: playlists.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final containsSong = playlist.songIds.contains(song.id);

        return _PlaylistChoiceTile(
          playlist: playlist,
          containsSong: containsSong,
          isBusy: isBusy,
          onTap: () => onPlaylistTap(playlist),
        );
      },
    );
  }
}

class _PlaylistChoiceTile extends StatelessWidget {
  const _PlaylistChoiceTile({
    required this.playlist,
    required this.containsSong,
    required this.isBusy,
    required this.onTap,
  });

  final PlaylistEntity playlist;
  final bool containsSong;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isBusy ? null : onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: containsSong
                ? _feedAccent.withValues(alpha: 0.07)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: containsSong
                  ? _feedAccent.withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              _PlaylistCover(playlist: playlist),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF151515),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.feedTrackCount(playlist.trackCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.54),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: containsSong
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('selected'),
                        color: _feedAccent,
                        size: 24,
                      )
                    : const Icon(
                        Icons.add_circle_outline_rounded,
                        key: ValueKey('add'),
                        color: Colors.black38,
                        size: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetArtwork extends StatelessWidget {
  const _SheetArtwork({required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: song.imageUrl.isEmpty
          ? const Icon(Icons.music_note_rounded, color: Colors.white70)
          : Image.network(
              song.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.music_note_rounded, color: Colors.white70),
            ),
    );
  }
}

class _PlaylistCover extends StatelessWidget {
  const _PlaylistCover({required this.playlist});

  final PlaylistEntity playlist;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: _feedAccent.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: playlist.coverUrl.isEmpty
          ? const Icon(Icons.queue_music_rounded, color: _feedAccent, size: 25)
          : Image.network(
              playlist.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.queue_music_rounded,
                color: _feedAccent,
                size: 25,
              ),
            ),
    );
  }
}

class _FeedPreTitle extends StatelessWidget {
  const _FeedPreTitle({required this.playCount});

  final int playCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      playCount > 0
          ? AppLocalizations.of(
              context,
            )!.feedPlaysCount(_formatCount(playCount))
          : AppLocalizations.of(context)!.feedNewTrackLabel,
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
    required this.progress,
  });

  final SongEntity song;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlay;
  final double progress;

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
                          child: Text(
                            AppLocalizations.of(context)!.feedFollowAction,
                            style: const TextStyle(
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
                progress: progress,
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
    required this.progress,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final double progress;

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
                  value: widget.isLoading && widget.progress <= 0
                      ? null
                      : widget.progress,
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
    return ColoredBox(
      color: _feedBlack,
      child: SafeArea(
        bottom: false,
        child: PageView(
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          children: const [_FeedSkeletonPage()],
        ),
      ),
    );
  }
}

class _FeedSkeletonPage extends StatelessWidget {
  const _FeedSkeletonPage();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final outerPadding = screenWidth >= 700 ? 28.0 : 12.0;
    final innerPadding = screenWidth >= 700 ? 24.0 : 16.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(outerPadding, 10, outerPadding, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF111111)),
            Positioned(
              top: 16,
              left: innerPadding,
              right: innerPadding,
              child: const _FeedTopBar(),
            ),
            Positioned(
              left: innerPadding,
              right: innerPadding + 90,
              bottom: 126,
              child: _FeedSkeletonBlock(height: 18, widthFactor: 0.65),
            ),
            Positioned(
              right: innerPadding,
              bottom: 150,
              child: const Column(
                children: [
                  _FeedSkeletonCircle(size: 28),
                  SizedBox(height: 20),
                  _FeedSkeletonCircle(size: 28),
                  SizedBox(height: 20),
                  _FeedSkeletonCircle(size: 28),
                ],
              ),
            ),
            Positioned(
              left: innerPadding,
              right: innerPadding,
              bottom: 14,
              child: Container(
                height: 104,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FeedSkeletonBlock(height: 20, widthFactor: 0.8),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        _FeedSkeletonCircle(size: 32),
                        SizedBox(width: 10),
                        Expanded(
                          child: _FeedSkeletonBlock(
                            height: 14,
                            widthFactor: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Center(child: CircularProgressIndicator(color: _feedAccent)),
          ],
        ),
      ),
    );
  }
}

class _FeedSkeletonBlock extends StatelessWidget {
  const _FeedSkeletonBlock({required this.height, required this.widthFactor});

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _FeedSkeletonCircle extends StatelessWidget {
  const _FeedSkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
      ),
    );
  }
}

class _FeedFooterPage extends StatelessWidget {
  const _FeedFooterPage({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback onRetry;

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
              if (isLoading) ...[
                const CircularProgressIndicator(color: _feedAccent),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.feedLoadingMoreMessage,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.cloud_off_outlined,
                  color: Colors.white38,
                  size: 46,
                ),
                const SizedBox(height: 12),
                Text(
                  message ??
                      AppLocalizations.of(context)!.feedLoadMoreFailedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _feedAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.feedRetryAction),
                ),
              ],
            ],
          ),
        ),
      ),
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

String _commentInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'L';
  }

  return trimmed.substring(0, 1).toUpperCase();
}
