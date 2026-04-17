import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> call(String email, String password) async {
    return await repository.login(email, password);
  }
}
