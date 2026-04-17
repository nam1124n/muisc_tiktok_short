import 'package:login_flutter/data/dto/language/app_language_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppLanguageLocalDataSource {
  Future<AppLanguageModel> getSavedLanguage();
  Future<void> saveLanguage(String languageCode);
}

class AppLanguageLocalDataSourceImpl implements AppLanguageLocalDataSource {
  static const _languageCodeKey = 'app_language_code';

  final SharedPreferences sharedPreferences;

  AppLanguageLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<AppLanguageModel> getSavedLanguage() async {
    final languageCode = sharedPreferences.getString(_languageCodeKey);
    return AppLanguageModel.fromLanguageCode(languageCode);
  }

  @override
  Future<void> saveLanguage(String languageCode) async {
    final model = AppLanguageModel.fromLanguageCode(languageCode);
    await sharedPreferences.setString(_languageCodeKey, model.languageCode);
  }
}
