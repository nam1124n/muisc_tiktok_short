import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/domain/repositories/profile_repository.dart';

class GetProfileByIdUseCase {
  GetProfileByIdUseCase(this.repository);

  final ProfileRepository repository;

  Future<ProfileEntity> call(String userId) async {
    return repository.getProfileById(userId);
  }
}
