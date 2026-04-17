import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<UserEntity> call(
    String fullName,
    String email,
    String password,
  ) async {
    return await repository.signUp(fullName, email, password);
  }
}
