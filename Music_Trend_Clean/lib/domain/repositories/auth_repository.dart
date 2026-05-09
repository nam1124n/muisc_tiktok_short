import 'package:login_flutter/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> signUp(
    String fullName,
    String email,
    String password,
    String ageGroup,
  );
  Future<UserEntity?> getCurrentUser();
  Stream<UserEntity?> watchCurrentUser();

  Future<void> resetPassword(String email);
  Future<void> resendEmailVerification(String email, String password);
  Future<void> sendCurrentUserEmailVerification();
  Future<void> reloadCurrentUser();
  Future<void> signOut();
}
