import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/utils/auth_input_validator.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
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
    authRepository: ref.read(authRepositoryProvider),
    loginUseCase: ref.read(loginUseCaseProvider),
    signUpUseCase: ref.read(signUpUseCaseProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;

  AuthNotifier({
    required this.authRepository,
    required this.loginUseCase,
    required this.signUpUseCase,
  }) : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    state = AuthLoading();

    try {
      final user = await loginUseCase(email, password);
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthFailure(ErrorMessageMapper.map(e));
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String ageGroup,
  }) async {
    state = AuthLoading();

    try {
      final user = await signUpUseCase(fullName, email, password, ageGroup);
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthFailure(ErrorMessageMapper.map(e));
    }
  }

  Future<void> syncCurrentUser() async {
    try {
      final user = await authRepository.getCurrentUser();
      state = user == null ? AuthInitial() : AuthSuccess(user);
    } catch (e) {
      state = AuthFailure(ErrorMessageMapper.map(e));
    }
  }

  Future<void> resendEmailVerification(String email, String password) async {
    state = AuthLoading();
    try {
      await authRepository.resendEmailVerification(email, password);
      state = AuthInitial();
    } catch (e) {
      state = AuthFailure(ErrorMessageMapper.map(e));
    }
  }

  void reset() {
    state = AuthInitial();
  }

  String? validateLoginInput({
    required String email,
    required String password,
    required String emailRequiredMessage,
    required String invalidEmailFormatMessage,
    required String passwordRequiredMessage,
  }) {
    return AuthInputValidator.validateLogin(
      email: email,
      password: password,
      emailRequiredMessage: emailRequiredMessage,
      invalidEmailFormatMessage: invalidEmailFormatMessage,
      passwordRequiredMessage: passwordRequiredMessage,
    );
  }

  String? validateSignUpInput({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String? ageGroup,
    required String fullNameRequiredMessage,
    required String emailRequiredMessage,
    required String invalidEmailFormatMessage,
    required String passwordRequiredMessage,
    required String passwordTooShortMessage,
    required String passwordWeakMessage,
    required String passwordsDoNotMatchMessage,
    required String ageGroupRequiredMessage,
  }) {
    return AuthInputValidator.validateSignUp(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      ageGroup: ageGroup,
      fullNameRequiredMessage: fullNameRequiredMessage,
      emailRequiredMessage: emailRequiredMessage,
      invalidEmailFormatMessage: invalidEmailFormatMessage,
      passwordRequiredMessage: passwordRequiredMessage,
      passwordTooShortMessage: passwordTooShortMessage,
      passwordWeakMessage: passwordWeakMessage,
      passwordsDoNotMatchMessage: passwordsDoNotMatchMessage,
      ageGroupRequiredMessage: ageGroupRequiredMessage,
    );
  }
}
