import 'package:login_flutter/domain/entities/app_language_entity.dart';
import 'package:login_flutter/domain/repositories/app_language_repository.dart';

class GetSavedLanguageUseCase {
  final AppLanguageRepository repository;

  GetSavedLanguageUseCase(this.repository);

  Future<AppLanguageEntity> call() async {
    return await repository.getSavedLanguage();
  }
}
