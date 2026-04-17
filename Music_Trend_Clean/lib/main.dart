import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/app_language_provider.dart';
import 'package:login_flutter/app/providers/app_language_state.dart';
import 'package:login_flutter/firebase_options.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/auth/login_screen.dart';
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
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const LoginScreen(),
    );
  }
}
