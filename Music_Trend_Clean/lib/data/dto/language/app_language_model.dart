import 'package:login_flutter/domain/entities/app_language_entity.dart';

class AppLanguageModel extends AppLanguageEntity {
  const AppLanguageModel({required super.languageCode});

  factory AppLanguageModel.fromLanguageCode(String? languageCode) {
    final safeCode = AppLanguageEntity.isSupported(languageCode ?? '')
        ? languageCode!
        : AppLanguageEntity.vietnamese;

    return AppLanguageModel(languageCode: safeCode);
  }

  factory AppLanguageModel.fromEntity(AppLanguageEntity entity) {
    return AppLanguageModel(languageCode: entity.languageCode);
  }
}
