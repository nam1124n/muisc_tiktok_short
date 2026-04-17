import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/app_language_provider.dart';
import 'package:login_flutter/app/providers/app_language_state.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/login_screen.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';
import 'package:login_flutter/ui/screen/search/providers/search_provider.dart';

class ProfileHeader extends ConsumerWidget {
  final Color textPrimary;

  const ProfileHeader({super.key, required this.textPrimary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageState = ref.watch(appLanguageNotifierProvider);
    final currentLanguageCode = languageState is AppLanguageLoaded
        ? languageState.language.languageCode
        : 'vi';

    return Row(
      children: [
        _HeaderIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          textPrimary: textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Text(
            l10n.profileTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PopupMenuButton<String>(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 46),
          onSelected: (value) async {
            if (value == 'vi' || value == 'en') {
              await ref
                  .read(appLanguageNotifierProvider.notifier)
                  .changeLanguage(value);
              return;
            }

            if (value == 'logout') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      l10n.logoutTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Text(l10n.logoutMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(l10n.confirm),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true && context.mounted) {
                // Actually clear Firebase session
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) {
                  return;
                }

                ref.invalidate(audioPlayerNotifierProvider);
                ref.invalidate(favoriteNotifierProvider);
                ref.invalidate(recentNotifierProvider);
                ref.invalidate(searchNotifierProvider);
                ref.invalidate(songNotifierProvider);
                ref.invalidate(profileNotifierProvider);
                ref.invalidate(authNotifierProvider);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              height: 36,
              child: Text(
                l10n.language,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20202B),
                ),
              ),
            ),
            CheckedPopupMenuItem<String>(
              value: 'vi',
              checked: currentLanguageCode == 'vi',
              child: Text(l10n.vietnamese),
            ),
            CheckedPopupMenuItem<String>(
              value: 'en',
              checked: currentLanguageCode == 'en',
              child: Text(l10n.english),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.logout,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: _HeaderIconButton(
            icon: Icons.settings_rounded,
            textPrimary: textPrimary,
            onPressed: null,
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    this.onPressed,
    required this.textPrimary,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: textPrimary),
        ),
      ),
    );
  }
}
