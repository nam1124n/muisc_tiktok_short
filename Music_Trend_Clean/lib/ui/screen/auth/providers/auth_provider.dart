import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static final RegExp _emailPattern = RegExp(
    r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
  );
  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasSpecialCharacter = RegExp(
    r'''[!@#$%^&*(),.?":{}|<>\[\]_\-+=/\\;']''',
  );

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
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return emailRequiredMessage;
    }
    if (!_emailPattern.hasMatch(trimmedEmail)) {
      return invalidEmailFormatMessage;
    }
    if (password.trim().isEmpty) {
      return passwordRequiredMessage;
    }

    return null;
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
    if (fullName.trim().isEmpty) {
      return fullNameRequiredMessage;
    }

    final loginValidation = validateLoginInput(
      email: email,
      password: password,
      emailRequiredMessage: emailRequiredMessage,
      invalidEmailFormatMessage: invalidEmailFormatMessage,
      passwordRequiredMessage: passwordRequiredMessage,
    );
    if (loginValidation != null) {
      return loginValidation;
    }

    if (password.length < 8) {
      return passwordTooShortMessage;
    }

    final isStrongPassword =
        _hasUppercase.hasMatch(password) &&
        _hasLowercase.hasMatch(password) &&
        _hasDigit.hasMatch(password) &&
        _hasSpecialCharacter.hasMatch(password);
    if (!isStrongPassword) {
      return passwordWeakMessage;
    }

    if (password != confirmPassword) {
      return passwordsDoNotMatchMessage;
    }

    if (ageGroup == null || ageGroup.trim().isEmpty) {
      return ageGroupRequiredMessage;
    }

    return null;
  }
}
