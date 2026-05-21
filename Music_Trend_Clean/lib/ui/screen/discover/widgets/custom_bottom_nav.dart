import 'package:flutter/material.dart';
import 'package:login_flutter/l10n/app_localizations.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.height = 72,
    this.isDark = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final metrics = _BottomNavMetrics.fromWidth(screenWidth);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.grey).withValues(
              alpha: isDark ? 0.08 : 0.2,
            ),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
        child: Row(
          children: [
            _buildNavItem(
              context: context,
              metrics: metrics,
              index: 0,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: l10n.discoverLabel,
              isDark: isDark,
            ),
            _buildNavItem(
              context: context,
              metrics: metrics,
              index: 1,
              icon: Icons.dynamic_feed_outlined,
              activeIcon: Icons.dynamic_feed,
              label: 'Feed',
              isDark: isDark,
            ),
            SizedBox(width: metrics.centerGap),
            _buildNavItem(
              context: context,
              metrics: metrics,
              index: 2,
              icon: Icons.library_music_outlined,
              activeIcon: Icons.library_music,
              label: l10n.yourAudioLabel,
              isDark: isDark,
            ),
            _buildNavItem(
              context: context,
              metrics: metrics,
              index: 3,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: l10n.profileTitle,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required _BottomNavMetrics metrics,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final bool isActive = currentIndex == index;
    final activeColor = isDark ? Colors.white : const Color(0xFF8C52FF);
    final Color color = isActive
        ? activeColor
        : isDark
        ? Colors.white.withValues(alpha: 0.52)
        : Colors.grey.shade600;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(metrics.tapRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.itemHorizontalGap,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.iconHorizontalPadding,
                    vertical: metrics.iconVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor.withValues(alpha: isDark ? 0.14 : 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      metrics.activePillRadius,
                    ),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: color,
                    size: metrics.iconSize,
                  ),
                ),
                SizedBox(height: metrics.labelSpacing),
                SizedBox(
                  height: metrics.labelHeight,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: color,
                          fontSize: metrics.labelFontSize,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
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
}

class _BottomNavMetrics {
  const _BottomNavMetrics({
    required this.horizontalPadding,
    required this.centerGap,
    required this.iconSize,
    required this.labelFontSize,
    required this.labelHeight,
    required this.labelSpacing,
    required this.tapRadius,
    required this.activePillRadius,
    required this.itemHorizontalGap,
    required this.iconHorizontalPadding,
    required this.iconVerticalPadding,
  });

  final double horizontalPadding;
  final double centerGap;
  final double iconSize;
  final double labelFontSize;
  final double labelHeight;
  final double labelSpacing;
  final double tapRadius;
  final double activePillRadius;
  final double itemHorizontalGap;
  final double iconHorizontalPadding;
  final double iconVerticalPadding;

  factory _BottomNavMetrics.fromWidth(double width) {
    if (width < 360) {
      return const _BottomNavMetrics(
        horizontalPadding: 4,
        centerGap: 52,
        iconSize: 22,
        labelFontSize: 10,
        labelHeight: 14,
        labelSpacing: 3,
        tapRadius: 14,
        activePillRadius: 18,
        itemHorizontalGap: 2,
        iconHorizontalPadding: 8,
        iconVerticalPadding: 6,
      );
    }

    if (width < 430) {
      return const _BottomNavMetrics(
        horizontalPadding: 8,
        centerGap: 60,
        iconSize: 24,
        labelFontSize: 10,
        labelHeight: 14,
        labelSpacing: 4,
        tapRadius: 16,
        activePillRadius: 20,
        itemHorizontalGap: 4,
        iconHorizontalPadding: 10,
        iconVerticalPadding: 6,
      );
    }

    if (width < 700) {
      return const _BottomNavMetrics(
        horizontalPadding: 12,
        centerGap: 72,
        iconSize: 25,
        labelFontSize: 11,
        labelHeight: 16,
        labelSpacing: 4,
        tapRadius: 18,
        activePillRadius: 22,
        itemHorizontalGap: 6,
        iconHorizontalPadding: 12,
        iconVerticalPadding: 7,
      );
    }

    return const _BottomNavMetrics(
      horizontalPadding: 20,
      centerGap: 96,
      iconSize: 28,
      labelFontSize: 12,
      labelHeight: 18,
      labelSpacing: 5,
      tapRadius: 20,
      activePillRadius: 24,
      itemHorizontalGap: 8,
      iconHorizontalPadding: 14,
      iconVerticalPadding: 8,
    );
  }
}
