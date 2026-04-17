import 'package:login_flutter/domain/entities/app_language_entity.dart';

abstract class AppLanguageRepository {
  Future<AppLanguageEntity> getSavedLanguage();
  Future<void> saveLanguage(AppLanguageEntity language);
}
