import 'package:login_flutter/domain/entities/app_language_entity.dart';
import 'package:login_flutter/domain/repositories/app_language_repository.dart';

class SaveLanguageUseCase {
  final AppLanguageRepository repository;

  SaveLanguageUseCase(this.repository);

  Future<void> call(AppLanguageEntity language) async {
    await repository.saveLanguage(language);
  }
}
