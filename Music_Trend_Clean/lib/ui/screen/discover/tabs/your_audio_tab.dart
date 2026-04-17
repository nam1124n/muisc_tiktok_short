import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:login_flutter/l10n/app_localizations.dart';

class YourAudioTab extends StatelessWidget {
  const YourAudioTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          _buildImportCard(
            title: l10n.importAudioFromVideo,
            subtitle: l10n.importAudioFromVideoSubtitle,
            icon: Icons.ondemand_video,
            buttonText: l10n.importButtonLabel,
            isPrimaryAction: true,
          ),
          const SizedBox(height: 16),
          _buildImportCard(
            title: l10n.importAudioFromDevice,
            subtitle: l10n.importAudioFromDeviceSubtitle,
            icon: Icons.folder_open,
            buttonText: l10n.browseButtonLabel,
            isPrimaryAction: false,
          ),
          const SizedBox(height: 32),
          _buildEmptyState(context),
          const SizedBox(height: 140), // Spacing for bottom nav
        ],
      ),
    );
  }

  Widget _buildImportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String buttonText,
    required bool isPrimaryAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Watermark icon on the right
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.music_note,
              size: 140,
              color: Colors.grey.shade100,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF), // Light purple
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF8C52FF)),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPrimaryAction
                          ? const Color(0xFF8C52FF)
                          : const Color(0xFFF3F4F6),
                      foregroundColor: isPrimaryAction
                          ? Colors.white
                          : const Color(0xFF8C52FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isPrimaryAction
                        ? Text(
                            buttonText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                buttonText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        // Dashed border container with icon
        CustomPaint(
          painter: DashedRectPainter(
            color: const Color(0xFFD8B4FE), // Light purple dash
            strokeWidth: 2,
            gap: 6,
          ),
          child: Container(
            width: 250,
            height: 160,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_music,
                  size: 48,
                  color: const Color(0xFFC084FC),
                ),
                const SizedBox(height: 8),
                // small visual flair lines
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 3,
                      height: [20.0, 30.0, 15.0, 25.0][index],
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9D5FF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.yourAudioEmptyTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            AppLocalizations.of(context)!.yourAudioEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8C52FF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.getStartedNow,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16),
        ),
      );

    var dashWidth = gap;
    var dashSpace = gap;
    double currentPos = 0.0;

    for (PathMetric metric in path.computeMetrics()) {
      while (currentPos < metric.length) {
        canvas.drawPath(
          metric.extractPath(currentPos, currentPos + dashWidth),
          paint,
        );
        currentPos += dashWidth + dashSpace;
      }
      currentPos = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
