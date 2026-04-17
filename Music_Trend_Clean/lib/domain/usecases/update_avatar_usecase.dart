import 'package:login_flutter/domain/repositories/profile_repository.dart';

class UpdateAvatarUseCase {
  final ProfileRepository repository;

  UpdateAvatarUseCase(this.repository);

  Future<void> call(String url) async {
    return await repository.updateAvatarUrl(url);
  }
}
