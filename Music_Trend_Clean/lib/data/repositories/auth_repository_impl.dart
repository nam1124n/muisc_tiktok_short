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
  ) async {
    try {
      final userModel = await remoteDataSource.signUp(
        fullName,
        email,
        password,
      );
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}
