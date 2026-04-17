import 'package:login_flutter/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<void> call(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('email khong duoc de trong. ');
    }
    await repository.resetPassword(email);
  }
}
