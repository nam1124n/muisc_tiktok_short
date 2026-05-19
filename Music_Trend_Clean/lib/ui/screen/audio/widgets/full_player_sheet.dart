import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/audio/widgets/audio_queue_sheet.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';

Future<void> showFullPlayerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FullPlayerSheet(),
  );
}

class FullPlayerSheet extends ConsumerStatefulWidget {
  const FullPlayerSheet({super.key});

  static const Color _surface = Color(0xFF0F0F10);
  static const Color _accent = Color(0xFFFF6A00);

  @override
  ConsumerState<FullPlayerSheet> createState() => _FullPlayerSheetState();
}

class _FullPlayerSheetState extends ConsumerState<FullPlayerSheet> {
  bool _showControls = false;

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerNotifierProvider);
    final playerNotifier = ref.read(audioPlayerNotifierProvider.notifier);
    final song = playerState.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final isFavorite = ref.watch(isFavoriteSongProvider(song.id));
    final isFavoriteBusy = ref.watch(isFavoriteSongBusyProvider(song.id));
    final progress = _progressValue(playerState.position, playerState.duration);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: Material(
        color: FullPlayerSheet._surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _CoverImage(imageUrl: song.imageUrl),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x66000000),
                                Color(0x26000000),
                                Color(0xB8000000),
                              ],
                              stops: [0, 0.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 22,
                          left: 20,
                          right: 88,
                          child: _showControls
                              ? _CompactTrackHeading(
                                  title: song.title,
                                  artist: song.artist,
                                )
                              : _TrackHeading(
                                  title: song.title,
                                  artist: song.artist,
                                ),
                        ),
                        Positioned(
                          top: 18,
                          right: 18,
                          child: _RoundIconButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            iconSize: 38,
                            backgroundColor: Colors.black,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Positioned.fill(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _showControls
                                ? _CompactControlsOverlay(
                                    key: const ValueKey('compact-controls'),
                                    onToggle: _toggleControls,
                                    isPlaying: playerState.isPlaying,
                                    isLoading: playerState.isLoading,
                                    canGoPrevious:
                                        playerState.currentIndex > 0 ||
                                        playerState.position.inSeconds > 3,
                                    canGoNext:
                                        playerState.currentIndex <
                                        playerState.playlist.length - 1,
                                    position: playerState.position,
                                    duration: playerState.duration,
                                    progress: progress,
                                    onPrevious: playerNotifier.previous,
                                    onPlayPause: () {
                                      if (playerState.isPlaying) {
                                        playerNotifier.pause();
                                      } else {
                                        playerNotifier.resume();
                                      }
                                    },
                                    onNext: playerNotifier.next,
                                    onSeek: (value) {
                                      playerNotifier.seek(
                                        _positionFromProgress(
                                          value,
                                          playerState.duration,
                                        ),
                                      );
                                    },
                                  )
                                : _WaveformOverlay(
                                    key: const ValueKey('waveform-controls'),
                                    onToggle: _toggleControls,
                                    progress: progress,
                                    position: playerState.position,
                                    duration: playerState.duration,
                                    onSeek: (value) {
                                      playerNotifier.seek(
                                        _positionFromProgress(
                                          value,
                                          playerState.duration,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 28,
                          child: GestureDetector(
                            onTap: () {},
                            child: const _CommentBar(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onVerticalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -300) {
                      showAudioQueueSheet(context);
                    }
                  },
                  child: _ActionBar(
                    isFavorite: isFavorite,
                    isFavoriteBusy: isFavoriteBusy,
                    onFavorite: () => ref
                        .read(favoriteNotifierProvider.notifier)
                        .toggleFavorite(song),
                    onQueue: () => showAudioQueueSheet(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _progressValue(Duration position, Duration duration) {
    if (duration <= Duration.zero) {
      return 0;
    }

    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  static Duration _positionFromProgress(double value, Duration duration) {
    if (duration <= Duration.zero) {
      return Duration.zero;
    }

    return Duration(
      milliseconds: (duration.inMilliseconds * value.clamp(0.0, 1.0)).round(),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF232326),
        child: Center(
          child: Icon(
            Icons.music_note_rounded,
            color: Colors.white54,
            size: 96,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFF232326),
        child: Center(
          child: Icon(
            Icons.music_note_rounded,
            color: Colors.white54,
            size: 96,
          ),
        ),
      ),
    );
  }
}

class _TrackHeading extends StatelessWidget {
  const _TrackHeading({required this.title, required this.artist});

  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 24,
            height: 1.12,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white.withValues(alpha: 0.78),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Behind this track',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 18,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactTrackHeading extends StatelessWidget {
  const _CompactTrackHeading({required this.title, required this.artist});

  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 23,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white.withValues(alpha: 0.68),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Behind this track',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaveformOverlay extends StatelessWidget {
  const _WaveformOverlay({
    super.key,
    required this.onToggle,
    required this.progress,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final VoidCallback onToggle;
  final double progress;
  final Duration position;
  final Duration duration;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onToggle,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 146,
          child: _WaveformProgress(progress: progress, onSeek: onSeek),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 116,
          child: Center(
            child: _TimePill(position: position, duration: duration),
          ),
        ),
      ],
    );
  }
}

class _CompactControlsOverlay extends StatelessWidget {
  const _CompactControlsOverlay({
    super.key,
    required this.onToggle,
    required this.isPlaying,
    required this.isLoading,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.position,
    required this.duration,
    required this.progress,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onSeek,
  });

  final VoidCallback onToggle;
  final bool isPlaying;
  final bool isLoading;
  final bool canGoPrevious;
  final bool canGoNext;
  final Duration position;
  final Duration duration;
  final double progress;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onToggle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 38),
                _RoundIconButton(
                  icon: Icons.skip_previous_rounded,
                  iconSize: 38,
                  backgroundColor: Colors.black,
                  foregroundColor: canGoPrevious
                      ? Colors.white
                      : Colors.white38,
                  onTap: canGoPrevious ? onPrevious : null,
                ),
                _RoundIconButton(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  iconSize: 48,
                  size: 76,
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  isLoading: isLoading,
                  loadingColor: Colors.white,
                  onTap: onPlayPause,
                ),
                _RoundIconButton(
                  icon: Icons.skip_next_rounded,
                  iconSize: 38,
                  backgroundColor: Colors.black,
                  foregroundColor: canGoNext ? Colors.white : Colors.white38,
                  onTap: canGoNext ? onNext : null,
                ),
                const SizedBox(width: 38),
              ],
            ),
          ),
        ),
        Positioned(
          left: 76,
          right: 76,
          bottom: 160,
          child: _CompactProgressLine(
            progress: progress,
            position: position,
            duration: duration,
            onSeek: onSeek,
          ),
        ),
      ],
    );
  }
}

class _CompactProgressLine extends StatelessWidget {
  const _CompactProgressLine({
    required this.progress,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final double progress;
  final Duration position;
  final Duration duration;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final width = context.size?.width;
        if (width == null || width <= 0) {
          return;
        }

        onSeek(details.localPosition.dx / width);
      },
      onHorizontalDragUpdate: (details) {
        final width = context.size?.width;
        if (width == null || width <= 0) {
          return;
        }

        onSeek(details.localPosition.dx / width);
      },
      child: SizedBox(
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 2, color: Colors.black.withValues(alpha: 0.62)),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(height: 2, color: FullPlayerSheet._accent),
              ),
            ),
            _TimePill(position: position, duration: duration),
          ],
        ),
      ),
    );
  }
}

class _WaveformProgress extends StatelessWidget {
  const _WaveformProgress({required this.progress, required this.onSeek});

  final double progress;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final width = context.size?.width;
        if (width == null || width <= 0) {
          return;
        }

        onSeek(details.localPosition.dx / width);
      },
      onHorizontalDragUpdate: (details) {
        final width = context.size?.width;
        if (width == null || width <= 0) {
          return;
        }

        onSeek(details.localPosition.dx / width);
      },
      child: SizedBox(
        height: 128,
        child: CustomPaint(
          painter: _WaveformPainter(progress: progress),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final progressX = size.width * progress;
    final playedPaint = Paint()
      ..color = FullPlayerSheet._accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final remainingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      guidePaint,
    );

    const barCount = 112;
    final gap = size.width / barCount;
    for (var i = 0; i < barCount; i++) {
      final x = gap * i + gap / 2;
      final wave = math.sin(i * 0.47) * 0.34 + math.sin(i * 0.19 + 1.8) * 0.24;
      final normalized = (0.52 + wave).clamp(0.18, 1.0);
      final height = 22 + normalized * 58;
      final paint = x <= progressX ? playedPaint : remainingPaint;
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: Colors.black.withValues(alpha: 0.9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(position),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatDuration(duration),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBar extends StatelessWidget {
  const _CommentBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF3F3A37).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Comment...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 18,
              ),
            ),
          ),
          const Text('🔥', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 24),
          const Text('👏', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 24),
          const Text('🥺', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isFavorite,
    required this.isFavoriteBusy,
    required this.onFavorite,
    required this.onQueue,
  });

  final bool isFavorite;
  final bool isFavoriteBusy;
  final VoidCallback onFavorite;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
          label: '3284',
          isBusy: isFavoriteBusy,
          onTap: isFavoriteBusy ? null : onFavorite,
        ),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: '4',
          onTap: () => _showActionMessage(context, 'Comments are coming soon.'),
        ),
        _ActionButton(
          icon: Icons.ios_share_rounded,
          onTap: () => _showActionMessage(context, 'Share is coming soon.'),
        ),
        _ActionButton(icon: Icons.queue_music_rounded, onTap: onQueue),
        _ActionButton(
          icon: Icons.more_horiz_rounded,
          onTap: () => _showMoreMenu(context),
        ),
      ],
    );
  }

  void _showActionMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showMoreMenu(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18181A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _MoreMenuTile(
                  icon: Icons.playlist_add_rounded,
                  label: 'Add to playlist',
                ),
                _MoreMenuTile(
                  icon: Icons.report_gmailerrorred_rounded,
                  label: 'Report track',
                ),
                _MoreMenuTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Track details',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.label,
    this.isBusy = false,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBusy)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 28),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => Navigator.of(context).pop(),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.size = 56,
    this.iconSize = 28,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
    this.isLoading = false,
    this.loadingColor = Colors.black,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final Color loadingColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: loadingColor,
                  ),
                )
              : Icon(icon, color: foregroundColor, size: iconSize),
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final safeDuration = duration < Duration.zero ? Duration.zero : duration;
  final minutes = safeDuration.inMinutes;
  final seconds = safeDuration.inSeconds
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds';
}
