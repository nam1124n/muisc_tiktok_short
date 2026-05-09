import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';
import 'package:login_flutter/domain/usecases/login_usecase.dart';
import 'package:login_flutter/domain/usecases/signup_usecase.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';

void main() {
  group('AuthNotifier signup', () {
    test('validateSignUpInput rejects weak password', () {
      final repository = FakeAuthRepository();
      final notifier = AuthNotifier(
        authRepository: repository,
        loginUseCase: LoginUseCase(repository),
        signUpUseCase: SignUpUseCase(repository),
      );

      final message = notifier.validateSignUpInput(
        fullName: 'Tester',
        email: 'tester@example.com',
        password: 'weakpass',
        confirmPassword: 'weakpass',
        ageGroup: 'adults',
        fullNameRequiredMessage: 'full-name',
        emailRequiredMessage: 'email-required',
        invalidEmailFormatMessage: 'email-invalid',
        passwordRequiredMessage: 'password-required',
        passwordTooShortMessage: 'password-short',
        passwordWeakMessage: 'password-weak',
        passwordsDoNotMatchMessage: 'password-mismatch',
        ageGroupRequiredMessage: 'age-required',
      );

      expect(message, 'password-weak');
    });

    test('validateSignUpInput rejects missing age group', () {
      final repository = FakeAuthRepository();
      final notifier = AuthNotifier(
        authRepository: repository,
        loginUseCase: LoginUseCase(repository),
        signUpUseCase: SignUpUseCase(repository),
      );

      final message = notifier.validateSignUpInput(
        fullName: 'Tester',
        email: 'tester@example.com',
        password: 'Strong@123',
        confirmPassword: 'Strong@123',
        ageGroup: null,
        fullNameRequiredMessage: 'full-name',
        emailRequiredMessage: 'email-required',
        invalidEmailFormatMessage: 'email-invalid',
        passwordRequiredMessage: 'password-required',
        passwordTooShortMessage: 'password-short',
        passwordWeakMessage: 'password-weak',
        passwordsDoNotMatchMessage: 'password-mismatch',
        ageGroupRequiredMessage: 'age-required',
      );

      expect(message, 'age-required');
    });

    test('signUp emits AuthSuccess when repository succeeds', () async {
      final repository = FakeAuthRepository(
        signUpResult: const UserEntity(
          id: 'user-1',
          email: 'tester@example.com',
          fullName: 'Tester',
          token: 'token',
          role: UserRoles.user,
          isEmailVerified: false,
        ),
      );
      final notifier = AuthNotifier(
        authRepository: repository,
        loginUseCase: LoginUseCase(repository),
        signUpUseCase: SignUpUseCase(repository),
      );

      await notifier.signUp(
        fullName: 'Tester',
        email: 'tester@example.com',
        password: 'Strong@123',
        ageGroup: 'adults',
      );

      expect(notifier.state, isA<AuthSuccess>());
    });

    test('signUp emits AuthFailure when repository throws', () async {
      final repository = FakeAuthRepository(
        signUpError: Exception('sign-up failed'),
      );
      final notifier = AuthNotifier(
        authRepository: repository,
        loginUseCase: LoginUseCase(repository),
        signUpUseCase: SignUpUseCase(repository),
      );

      await notifier.signUp(
        fullName: 'Tester',
        email: 'tester@example.com',
        password: 'Strong@123',
        ageGroup: 'adults',
      );

      expect(notifier.state, isA<AuthFailure>());
      expect((notifier.state as AuthFailure).message, 'sign-up failed');
    });
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signUpResult, this.signUpError});

  final UserEntity? signUpResult;
  final Object? signUpError;

  @override
  Future<UserEntity> login(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> signUp(
    String fullName,
    String email,
    String password,
    String ageGroup,
  ) async {
    if (signUpError != null) {
      throw signUpError!;
    }

    return signUpResult ??
        UserEntity(
          id: 'user-1',
          email: email,
          fullName: fullName,
          token: 'token',
          role: UserRoles.user,
          isEmailVerified: false,
        );
  }

  @override
  Future<UserEntity?> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Stream<UserEntity?> watchCurrentUser() => const Stream.empty();

  @override
  Future<void> resetPassword(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> resendEmailVerification(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendCurrentUserEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<void> reloadCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }
}
