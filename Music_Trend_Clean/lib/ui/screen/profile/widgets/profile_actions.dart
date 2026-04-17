import 'package:flutter/material.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/profile/edit_profile_screen.dart';
import 'package:share_plus/share_plus.dart';

class ProfileActions extends StatelessWidget {
  final ProfileEntity profile;
  final Color primaryColor;
  final Color textPrimary;

  const ProfileActions({
    super.key,
    required this.profile,
    required this.primaryColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8C5BFF), Color(0xFFB985FF)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(currentProfile: profile),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    l10n.editProfileButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  final shareText = l10n.profileShareMessage(
                    profile.username,
                    profile.followers,
                  );
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
                child: Center(
                  child: Text(
                    l10n.shareButton,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
