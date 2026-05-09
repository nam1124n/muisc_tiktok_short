import 'package:login_flutter/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<void> call(String email) async {
    await repository.resetPassword(email.trim());
  }
}
