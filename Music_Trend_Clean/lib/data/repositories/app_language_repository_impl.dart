import 'package:login_flutter/data/datasource/local/app_language_local_data_source.dart';
import 'package:login_flutter/domain/entities/app_language_entity.dart';
import 'package:login_flutter/domain/repositories/app_language_repository.dart';

class AppLanguageRepositoryImpl implements AppLanguageRepository {
  final AppLanguageLocalDataSource localDataSource;

  AppLanguageRepositoryImpl({required this.localDataSource});

  @override
  Future<AppLanguageEntity> getSavedLanguage() async {
    try {
      return await localDataSource.getSavedLanguage();
    } catch (e) {
      throw Exception('Failed to get saved language: $e');
    }
  }

  @override
  Future<void> saveLanguage(AppLanguageEntity language) async {
    try {
      await localDataSource.saveLanguage(language.languageCode);
    } catch (e) {
      throw Exception('Failed to save language: $e');
    }
  }
}
