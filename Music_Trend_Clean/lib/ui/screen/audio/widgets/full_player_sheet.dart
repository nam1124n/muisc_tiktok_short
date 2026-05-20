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
  final GlobalKey _playerStackKey = GlobalKey();
  final math.Random _random = math.Random();
  final List<_ReactionBubble> _reactions = [];
  static const List<String> _reactionEmojis = ['🔥', '👏', '🥺'];
  bool _showControls = false;

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _spawnReaction(String emoji, Offset globalPosition) {
    final renderBox =
        _playerStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final start = renderBox.globalToLocal(globalPosition);
    const burstCount = 18;

    for (var index = 0; index < burstCount; index++) {
      Future.delayed(Duration(milliseconds: index * 24), () {
        if (!mounted) {
          return;
        }

        final id =
            '${DateTime.now().microsecondsSinceEpoch}-$index-${_random.nextInt(999)}';
        final bubble = _ReactionBubble(
          id: id,
          emoji: index < 8
              ? emoji
              : _reactionEmojis[_random.nextInt(_reactionEmojis.length)],
          start: start.translate(
            (_random.nextDouble() * 52) - 26,
            (_random.nextDouble() * 18) - 8,
          ),
          drift: (_random.nextDouble() * 150) - 75,
          lift: 120 + _random.nextDouble() * 210,
          size: 22 + _random.nextDouble() * 13,
          duration: Duration(milliseconds: 1050 + _random.nextInt(650)),
        );

        setState(() => _reactions.add(bubble));
        Future.delayed(bubble.duration + const Duration(milliseconds: 80), () {
          if (!mounted) {
            return;
          }
          setState(() {
            _reactions.removeWhere((reaction) => reaction.id == id);
          });
        });
      });
    }
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
            child: Stack(
              key: _playerStackKey,
              children: [
                Column(
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
                                        key: const ValueKey(
                                          'waveform-controls',
                                        ),
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
                        onReaction: _spawnReaction,
                        onQueue: () => showAudioQueueSheet(context),
                      ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        for (final reaction in _reactions)
                          _FlyingReaction(
                            key: ValueKey(reaction.id),
                            reaction: reaction,
                          ),
                      ],
                    ),
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
            fontSize: 26,
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
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 20,
            height: 1.12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white.withValues(alpha: 0.72),
              size: 18,
            ),
            const SizedBox(width: 9),
            Text(
              'Behind this track',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 15,
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
            fontSize: 24,
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
            fontSize: 19,
            height: 1.15,
            fontWeight: FontWeight.w600,
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
              size: 18,
            ),
            const SizedBox(width: 9),
            Text(
              'Behind this track',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 15,
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
          bottom: 92,
          child: _WaveformProgress(progress: progress, onSeek: onSeek),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 74,
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
                  iconSize: 32,
                  size: 52,
                  backgroundColor: Colors.black.withValues(alpha: 0.44),
                  foregroundColor: canGoPrevious
                      ? Colors.white
                      : Colors.white38,
                  onTap: canGoPrevious ? onPrevious : null,
                ),
                _RoundIconButton(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  iconSize: 40,
                  size: 66,
                  backgroundColor: Colors.black.withValues(alpha: 0.58),
                  foregroundColor: Colors.white,
                  isLoading: isLoading,
                  loadingColor: Colors.white,
                  onTap: onPlayPause,
                ),
                _RoundIconButton(
                  icon: Icons.skip_next_rounded,
                  iconSize: 32,
                  size: 52,
                  backgroundColor: Colors.black.withValues(alpha: 0.44),
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
        height: 82,
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
      final height = 16 + normalized * 40;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: Colors.black.withValues(alpha: 0.9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(position),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(duration),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.emoji, required this.onReaction});

  final String emoji;
  final void Function(String emoji, Offset globalPosition) onReaction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          return;
        }

        onReaction(
          emoji,
          renderBox.localToGlobal(renderBox.size.center(Offset.zero)),
        );
      },
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 120),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _ReactionBubble {
  const _ReactionBubble({
    required this.id,
    required this.emoji,
    required this.start,
    required this.drift,
    required this.lift,
    required this.size,
    required this.duration,
  });

  final String id;
  final String emoji;
  final Offset start;
  final double drift;
  final double lift;
  final double size;
  final Duration duration;
}

class _FlyingReaction extends StatelessWidget {
  const _FlyingReaction({super.key, required this.reaction});

  final _ReactionBubble reaction;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reaction.duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final wobble = math.sin(value * math.pi * 2.6) * 14;
        final x = reaction.start.dx + reaction.drift * value + wobble;
        final y = reaction.start.dy - reaction.lift * value;
        final opacity = value < 0.12
            ? (value / 0.12).clamp(0.0, 1.0)
            : (1 - value).clamp(0.0, 1.0);
        final scale = 0.58 + math.sin(value * math.pi) * 0.48;

        return Positioned(
          left: x - 16,
          top: y - 16,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Text(reaction.emoji, style: TextStyle(fontSize: reaction.size)),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isFavorite,
    required this.isFavoriteBusy,
    required this.onFavorite,
    required this.onReaction,
    required this.onQueue,
  });

  final bool isFavorite;
  final bool isFavoriteBusy;
  final VoidCallback onFavorite;
  final void Function(String emoji, Offset globalPosition) onReaction;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
          label: '3284',
          isBusy: isFavoriteBusy,
          onTap: isFavoriteBusy ? null : onFavorite,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReactionButton(emoji: '🔥', onReaction: onReaction),
            const SizedBox(width: 18),
            _ReactionButton(emoji: '👏', onReaction: onReaction),
            const SizedBox(width: 18),
            _ReactionButton(emoji: '🥺', onReaction: onReaction),
          ],
        ),
        _ActionButton(icon: Icons.queue_music_rounded, onTap: onQueue),
      ],
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
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 25),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
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
