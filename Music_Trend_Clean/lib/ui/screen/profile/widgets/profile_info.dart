import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';

class ProfileInfo extends ConsumerWidget {
  final ProfileEntity profile;
  final Color primaryColor;
  final Color textPrimary;

  const ProfileInfo({
    super.key,
    required this.profile,
    required this.primaryColor,
    required this.textPrimary,
  });

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && context.mounted) {
      ref
          .read(profileNotifierProvider.notifier)
          .updateAvatar(imagePath: image.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(context, ref),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF3D7BC), Color(0xFFE6BB95)],
                  ),
                  image: profile.avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(profile.avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: profile.avatarUrl.isEmpty
                    ? Center(
                        child: Container(
                          width: 42,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFD9B28E),
                              width: 1.1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: 16,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFC59773),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 9,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFECCDAE),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          profile.username,
          style: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        if (profile.ageGroup != ProfileAgeGroups.preferNotToSay) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _ageGroupLabel(l10n, profile.ageGroup),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ProfileStatChip(
                label: l10n.followersLabel,
                value: profile.followers.toString(),
                primaryColor: primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileStatChip(
                label: l10n.followingLabel,
                value: profile.following.toString(),
                primaryColor: primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileStatChip(
                label: l10n.likesLabel,
                value: profile.likes.toString(),
                primaryColor: primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _ageGroupLabel(AppLocalizations l10n, String ageGroup) {
    switch (ageGroup) {
      case ProfileAgeGroups.under13:
        return l10n.ageGroupUnder13;
      case ProfileAgeGroups.teens:
        return l10n.ageGroupTeens;
      case ProfileAgeGroups.adults:
        return l10n.ageGroupAdults;
      default:
        return l10n.ageGroupPreferNotToSay;
    }
  }
}

class _ProfileStatChip extends StatelessWidget {
  const _ProfileStatChip({
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  final String label;
  final String value;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8E889C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
