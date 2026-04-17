import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final ProfileEntity currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.currentProfile.username,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final l10n = AppLocalizations.of(context)!;
    final newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.usernameRequired)));
      return;
    }

    if (newUsername != widget.currentProfile.username) {
      ref
          .read(profileNotifierProvider.notifier)
          .updateProfileInfo(username: newUsername);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FB),
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF20202B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.changeUsername,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF20202B).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: l10n.enterYourUsername,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFA066FF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: const Color(0xFFA066FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  l10n.saveChanges,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Colors.white,
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
