import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';
import 'package:login_flutter/data/datasource/remote/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      // Gọi lên Remote Data
      final userModel = await remoteDataSource.login(email, password);
      // userModel vốn dĩ kế thừa UserEntity nên return nó thẳng luôn hợp lệ
      return userModel;
    } catch (e) {
      // Trong thực tế sẽ quăng Left(Failure) theo thư viện dartz (bỏ qua cho dễ hiểu)
      rethrow;
    }
  }

  @override
  Future<UserEntity> signUp(
    String fullName,
    String email,
    String password,
    String ageGroup,
  ) async {
    try {
      final userModel = await remoteDataSource.signUp(
        fullName,
        email,
        password,
        ageGroup,
      );
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      return await remoteDataSource.getCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<UserEntity?> watchCurrentUser() {
    return remoteDataSource.watchCurrentUser();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resendEmailVerification(String email, String password) async {
    try {
      await remoteDataSource.resendEmailVerification(email, password);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendCurrentUserEmailVerification() async {
    try {
      await remoteDataSource.sendCurrentUserEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> reloadCurrentUser() async {
    try {
      await remoteDataSource.reloadCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
