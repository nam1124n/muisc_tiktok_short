import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/data/datasource/remote/auth_remote_data_source.dart';
import 'package:login_flutter/data/repositories/auth_repository_impl.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';
import 'package:login_flutter/domain/usecases/login_usecase.dart';
import 'package:login_flutter/domain/usecases/signup_usecase.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.read(authRepositoryProvider));
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    signUpUseCase: ref.read(signUpUseCaseProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;

  AuthNotifier({required this.loginUseCase, required this.signUpUseCase})
    : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    state = AuthLoading();

    try {
      final user = await loginUseCase(email, password);
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthFailure(e.toString());
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = AuthLoading();

    try {
      final user = await signUpUseCase(fullName, email, password);
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthFailure(e.toString());
    }
  }

  void reset() {
    state = AuthInitial();
  }
}
