import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';
import 'package:login_flutter/ui/screen/auth/forgot_password/forgot_password_screen.dart';
import 'package:login_flutter/ui/screen/auth/signup_screen.dart';

import 'package:login_flutter/ui/screen/audio/providers/audio_player_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/favorites_provider.dart';
import 'package:login_flutter/ui/screen/discover/providers/recents_provider.dart';
import 'package:login_flutter/ui/screen/search/providers/search_provider.dart';
import 'package:login_flutter/ui/screen/admin/providers/song_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/profile_provider.dart';
import 'package:login_flutter/ui/screen/profile/providers/playlist_provider.dart';
import 'package:login_flutter/ui/screen/my_audios/providers/my_audios_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(authNotifierProvider.notifier);
    final validationMessage = notifier.validateLoginInput(
      email: _emailController.text,
      password: _passwordController.text,
      emailRequiredMessage: l10n.emailRequiredMessage,
      invalidEmailFormatMessage: l10n.invalidEmailFormatMessage,
      passwordRequiredMessage: l10n.passwordRequiredMessage,
    );

    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage), backgroundColor: Colors.red),
      );
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.message), backgroundColor: Colors.red),
      );
    } else if (authState is AuthSuccess) {
      _invalidateSessionScopedProviders();
      ref.read(authNotifierProvider.notifier).reset();

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _invalidateSessionScopedProviders() {
    ref.invalidate(audioPlayerNotifierProvider);
    ref.invalidate(favoriteNotifierProvider);
    ref.invalidate(recentNotifierProvider);
    ref.invalidate(searchNotifierProvider);
    ref.invalidate(songNotifierProvider);
    ref.invalidate(adminSongNotifierProvider);
    ref.invalidate(profileNotifierProvider);
    ref.invalidate(playlistNotifierProvider);
    ref.invalidate(myAudiosProvider);
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String hintText, {
    TextStyle? hintStyle,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle:
          hintStyle ??
          Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 48.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.welcomeBack,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.signInSubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.emailAddress, style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration(
                            context,
                            'name@example.com',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(l10n.password, style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration(
                            context,
                            '••••••••',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[400],
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.forgotPassword,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: state is AuthLoading ? null : _login,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.login,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${l10n.noAccount} ',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.signUp,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
