import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/main.dart';
import 'package:login_flutter/ui/screen/auth/login_screen.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/app/providers/session_provider.dart';

void main() {
  group('AuthGate routing', () {
    test('returns verifyEmail for unverified normal user', () {
      final state = SessionState.unauthenticated().copyWith(
        currentUser: _user(isEmailVerified: false),
      );

      expect(
        resolveAuthGateDestination(state),
        AuthGateDestination.verifyEmail,
      );
    });

    test('returns home for unverified admin email', () {
      final state = SessionState.unauthenticated().copyWith(
        currentUser: _user(email: 'admin@gmail.com', isEmailVerified: false),
      );

      expect(resolveAuthGateDestination(state), AuthGateDestination.home);
    });
  });

  group('Auth widgets', () {
    testWidgets('AuthGate shows loading indicator while session is loading', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository(
        getCurrentUserFuture: Completer<UserEntity?>().future,
      );
      addTearDown(authRepository.dispose);

      await tester.pumpWidget(_buildTestApp(authRepository, const AuthGate()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AuthGate shows LoginScreen when unauthenticated', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository(currentUser: null);
      addTearDown(authRepository.dispose);

      await tester.pumpWidget(_buildTestApp(authRepository, const AuthGate()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Chào mừng quay lại'), findsOneWidget);
    });

    testWidgets('AuthGate shows verification screen for unverified user', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository(
        currentUser: _user(isEmailVerified: false),
      );
      addTearDown(authRepository.dispose);

      await tester.pumpWidget(_buildTestApp(authRepository, const AuthGate()));
      await tester.pumpAndSettle();

      expect(find.text('Xác thực email của bạn'), findsOneWidget);
    });

    testWidgets('LoginScreen shows validation snackbar when email is empty', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository(currentUser: null);
      addTearDown(authRepository.dispose);

      await tester.pumpWidget(
        _buildTestApp(authRepository, const LoginScreen()),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pump();

      expect(find.text('Vui lòng nhập email.'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

Widget _buildTestApp(AuthRepository authRepository, Widget home) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    child: MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
  );
}

UserEntity _user({
  String email = 'user@example.com',
  bool isEmailVerified = true,
  String role = UserRoles.user,
}) {
  return UserEntity(
    id: 'user-1',
    email: email,
    fullName: 'Tester',
    token: 'token',
    role: role,
    isEmailVerified: isEmailVerified,
  );
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.currentUser,
    this.getCurrentUserError,
    Future<UserEntity?>? getCurrentUserFuture,
  }) : _getCurrentUserFuture = getCurrentUserFuture;

  UserEntity? currentUser;
  final Object? getCurrentUserError;
  final Future<UserEntity?>? _getCurrentUserFuture;
  final StreamController<UserEntity?> _sessionController =
      StreamController<UserEntity?>.broadcast();

  @override
  Future<UserEntity?> getCurrentUser() async {
    if (_getCurrentUserFuture != null) {
      return _getCurrentUserFuture;
    }

    if (getCurrentUserError != null) {
      throw getCurrentUserError!;
    }

    return currentUser;
  }

  @override
  Stream<UserEntity?> watchCurrentUser() => _sessionController.stream;

  @override
  Future<UserEntity> login(String email, String password) async {
    final user = currentUser ?? _user(email: email);
    currentUser = user;
    _sessionController.add(user);
    return user;
  }

  @override
  Future<UserEntity> signUp(
    String fullName,
    String email,
    String password,
    String ageGroup,
  ) async {
    final user = _user(email: email, isEmailVerified: false);
    currentUser = user;
    _sessionController.add(user);
    return user;
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> resendEmailVerification(String email, String password) async {}

  @override
  Future<void> sendCurrentUserEmailVerification() async {}

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<void> signOut() async {
    currentUser = null;
    _sessionController.add(null);
  }

  Future<void> dispose() async {
    await _sessionController.close();
  }
}
