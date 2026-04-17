import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/domain/repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<ProfileEntity> call() async {
    return await repository.getProfile();
  }
}
