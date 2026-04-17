import 'package:flutter/material.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';

class ProfileStats extends StatelessWidget {
  final ProfileEntity profile;
  final Color textPrimary;
  final Color textMuted;

  const ProfileStats({
    super.key,
    required this.profile,
    required this.textPrimary,
    required this.textMuted,
  });

  String _formatStat(int stat) {
    if (stat >= 1000) {
      return '${(stat / 1000).toStringAsFixed(stat % 1000 == 0 ? 0 : 1)}k';
    }
    return stat.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          value: _formatStat(profile.followers),
          label: l10n.followersLabel,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        _StatItem(
          value: _formatStat(profile.following),
          label: l10n.followingLabel,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        _StatItem(
          value: _formatStat(profile.likes),
          label: l10n.likesLabel,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.textPrimary,
    required this.textMuted,
  });

  final String value;
  final String label;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: textMuted.withValues(alpha: 0.95),
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
