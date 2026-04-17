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
  final Color textMuted;

  const ProfileInfo({
    super.key,
    required this.profile,
    required this.primaryColor,
    required this.textPrimary,
    required this.textMuted,
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
                width: 96,
                height: 96,
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
                right: -4,
                bottom: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.username,
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.profileIdLabel(profile.id),
          style: TextStyle(
            color: textMuted.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}
