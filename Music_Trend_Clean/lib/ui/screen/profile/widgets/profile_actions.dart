import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/profile/edit_profile_screen.dart';
import 'package:login_flutter/ui/screen/profile/public_profile_screen.dart';
import 'package:share_plus/share_plus.dart';

class ProfileActions extends StatelessWidget {
  const ProfileActions({
    super.key,
    required this.profile,
    required this.primaryColor,
  });

  final ProfileEntity profile;
  final Color primaryColor;

  String _shareLink() {
    return AppConfig.buildPublicProfileUrl(profile.id);
  }

  String _shareMessage(AppLocalizations l10n) {
    return '${l10n.profileShareMessage(profile.username, profile.followers)}\n${_shareLink()}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: l10n.editProfileButton,
            icon: Icons.edit_outlined,
            primaryColor: primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(currentProfile: profile),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: l10n.shareButton,
            icon: Icons.share_outlined,
            primaryColor: primaryColor,
            onTap: () => _showShareSheet(context),
          ),
        ),
      ],
    );
  }

  Future<void> _showShareSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final link = _shareLink();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
                  Text(
                    l10n.shareButton,
                    style: const TextStyle(
                      color: Color(0xFF20202B),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F2FD),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      link,
                      style: const TextStyle(
                        color: Color(0xFF5C5570),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ShareSheetAction(
                    icon: Icons.link_rounded,
                    label: l10n.copyProfileLink,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (!sheetContext.mounted) {
                        return;
                      }

                      Navigator.of(sheetContext).pop();
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.profileLinkCopiedMessage)),
                      );
                    },
                  ),
                  _ShareSheetAction(
                    icon: Icons.send_rounded,
                    label: l10n.shareProfileAction,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      SharePlus.instance.share(
                        ShareParams(text: _shareMessage(l10n)),
                      );
                    },
                  ),
                  _ShareSheetAction(
                    icon: Icons.public_rounded,
                    label: l10n.viewPublicProfile,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PublicProfileScreen(profileId: profile.id),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primaryColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C5BFF), Color(0xFFB985FF)],
        ),
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

class _ShareSheetAction extends StatelessWidget {
  const _ShareSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFA066FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFA066FF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF20202B),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
