import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/app/providers/app_language_provider.dart';
import 'package:login_flutter/app/providers/app_language_state.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/app/theme/app_theme.dart';
import 'package:login_flutter/firebase_options.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/auth/login_screen.dart';
import 'package:login_flutter/ui/screen/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(appLanguageNotifierProvider);

    final locale = languageState is AppLanguageLoaded
        ? Locale(languageState.language.languageCode)
        : const Locale('vi');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const AuthGate(),
    );
  }
}

enum AuthGateDestination { loading, sessionError, login, verifyEmail, home }

AuthGateDestination resolveAuthGateDestination(SessionState sessionState) {
  if (sessionState.isLoading) {
    return AuthGateDestination.loading;
  }

  if (sessionState.errorMessage != null && !sessionState.isAuthenticated) {
    return AuthGateDestination.sessionError;
  }

  if (!sessionState.isAuthenticated) {
    return AuthGateDestination.login;
  }

  final isSystemAdmin =
      sessionState.isAdmin || AppConfig.isAdminEmail(sessionState.email);
  if (!sessionState.isEmailVerified && !isSystemAdmin) {
    return AuthGateDestination.verifyEmail;
  }

  return AuthGateDestination.home;
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    return switch (resolveAuthGateDestination(sessionState)) {
      AuthGateDestination.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthGateDestination.sessionError => _SessionErrorScreen(
        message: sessionState.errorMessage!,
      ),
      AuthGateDestination.login => const LoginScreen(),
      AuthGateDestination.verifyEmail => const _EmailVerificationScreen(),
      AuthGateDestination.home => const HomeScreen(),
    };
  }
}

class _SessionErrorScreen extends ConsumerWidget {
  const _SessionErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ref.read(sessionProvider.notifier).loadCurrentUser();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailVerificationScreen extends ConsumerStatefulWidget {
  const _EmailVerificationScreen();

  @override
  ConsumerState<_EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<_EmailVerificationScreen> {
  Future<void> _resendVerificationEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(sessionProvider.notifier).resendVerificationEmail();
    if (!context.mounted) {
      return;
    }

    final sessionState = ref.read(sessionProvider);
    if (sessionState.actionErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sessionState.actionErrorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.verificationEmailSentMessage)));
  }

  Future<void> _refreshVerificationStatus(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(sessionProvider.notifier).refreshCurrentUser();
    if (!context.mounted) {
      return;
    }

    final sessionState = ref.read(sessionProvider);
    if (sessionState.actionErrorMessage != null) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sessionState.actionErrorMessage ??
                l10n.genericVerificationErrorMessage,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sessionState = ref.watch(sessionProvider);
    final email = sessionState.email;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.emailVerificationTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.emailVerificationSubtitle(email),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: sessionState.isSendingVerificationEmail
                        ? null
                        : () => _resendVerificationEmail(context),
                    child: sessionState.isSendingVerificationEmail
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.resendVerificationEmail),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: sessionState.isRefreshingCurrentUser
                        ? null
                        : () => _refreshVerificationStatus(context),
                    child: sessionState.isRefreshingCurrentUser
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.checkVerificationStatus),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: sessionState.isSigningOut ? null : _signOut,
                    child: Text(l10n.logout),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
