import 'package:flutter/material.dart';
import 'package:login_flutter/l10n/app_localizations.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
              label: l10n.discoverLabel,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month,
              label: l10n.genreLabel,
            ),
            const SizedBox(width: 60),
            _buildNavItem(
              index: 2,
              icon: Icons.library_music_outlined,
              activeIcon: Icons.library_music,
              label: l10n.yourAudioLabel,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: l10n.profileTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = currentIndex == index;
    final Color color = isActive ? const Color(0xFF8C52FF) : Colors.grey;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isActive ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
