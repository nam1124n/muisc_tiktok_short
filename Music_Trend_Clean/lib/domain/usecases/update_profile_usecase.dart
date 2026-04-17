import 'package:login_flutter/domain/repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<void> call(String username) async {
    return await repository.updateProfile(username);
  }
}
