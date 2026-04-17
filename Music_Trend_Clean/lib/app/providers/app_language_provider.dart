import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/providers/app_language_state.dart';
import 'package:login_flutter/data/datasource/local/app_language_local_data_source.dart';
import 'package:login_flutter/data/repositories/app_language_repository_impl.dart';
import 'package:login_flutter/domain/entities/app_language_entity.dart';
import 'package:login_flutter/domain/repositories/app_language_repository.dart';
import 'package:login_flutter/domain/usecases/get_saved_language_usecase.dart';
import 'package:login_flutter/domain/usecases/save_language_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const defaultAppLanguage = AppLanguageEntity(
  languageCode: AppLanguageEntity.vietnamese,
);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

final appLanguageLocalDataSourceProvider = Provider<AppLanguageLocalDataSource>(
  (ref) {
    return AppLanguageLocalDataSourceImpl(
      sharedPreferences: ref.read(sharedPreferencesProvider),
    );
  },
);

final appLanguageRepositoryProvider = Provider<AppLanguageRepository>((ref) {
  return AppLanguageRepositoryImpl(
    localDataSource: ref.read(appLanguageLocalDataSourceProvider),
  );
});

final getSavedLanguageUseCaseProvider = Provider<GetSavedLanguageUseCase>((
  ref,
) {
  return GetSavedLanguageUseCase(ref.read(appLanguageRepositoryProvider));
});

final saveLanguageUseCaseProvider = Provider<SaveLanguageUseCase>((ref) {
  return SaveLanguageUseCase(ref.read(appLanguageRepositoryProvider));
});

final appLanguageNotifierProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguageState>((ref) {
      return AppLanguageNotifier(
        getSavedLanguageUseCase: ref.read(getSavedLanguageUseCaseProvider),
        saveLanguageUseCase: ref.read(saveLanguageUseCaseProvider),
      );
    });

class AppLanguageNotifier extends StateNotifier<AppLanguageState> {
  final GetSavedLanguageUseCase getSavedLanguageUseCase;
  final SaveLanguageUseCase saveLanguageUseCase;

  AppLanguageNotifier({
    required this.getSavedLanguageUseCase,
    required this.saveLanguageUseCase,
  }) : super(const AppLanguageLoaded(language: defaultAppLanguage)) {
    loadSavedLanguage();
  }

  Future<void> loadSavedLanguage() async {
    try {
      final language = await getSavedLanguageUseCase();
      state = AppLanguageLoaded(language: language);
    } catch (e) {
      state = AppLanguageError(message: e.toString());
      state = const AppLanguageLoaded(language: defaultAppLanguage);
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    final currentLanguage = _currentLanguage;

    if (!AppLanguageEntity.isSupported(languageCode)) {
      state = const AppLanguageError(message: 'Unsupported language code');
      state = AppLanguageLoaded(language: currentLanguage);
      return;
    }

    if (currentLanguage.languageCode == languageCode) {
      return;
    }

    final nextLanguage = AppLanguageEntity(languageCode: languageCode);

    try {
      await saveLanguageUseCase(nextLanguage);
      state = AppLanguageLoaded(language: nextLanguage);
    } catch (e) {
      state = AppLanguageError(message: e.toString());
      state = AppLanguageLoaded(language: currentLanguage);
    }
  }

  AppLanguageEntity get _currentLanguage {
    final currentState = state;
    if (currentState is AppLanguageLoaded) {
      return currentState.language;
    }
    return defaultAppLanguage;
  }
}
