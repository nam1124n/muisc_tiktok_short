import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:login_flutter/app/providers/session_provider.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';

void main() {
  group('SessionNotifier', () {
    test('loads current user on startup', () async {
      final repository = FakeSessionAuthRepository(
        currentUser: _user(isEmailVerified: false),
      );
      final notifier = SessionNotifier(authRepository: repository);
      addTearDown(notifier.dispose);
      addTearDown(repository.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.isEmailVerified, isFalse);
    });

    test('refreshCurrentUser updates the latest verification state', () async {
      late final FakeSessionAuthRepository repository;
      repository = FakeSessionAuthRepository(
        currentUser: _user(isEmailVerified: false),
        onReloadCurrentUser: () {
          repository.currentUser = _user(isEmailVerified: true);
        },
      );
      final notifier = SessionNotifier(authRepository: repository);
      addTearDown(notifier.dispose);
      addTearDown(repository.dispose);

      await Future<void>.delayed(Duration.zero);
      await notifier.refreshCurrentUser();

      expect(notifier.state.isRefreshingCurrentUser, isFalse);
      expect(notifier.state.isEmailVerified, isTrue);
      expect(notifier.state.actionErrorMessage, isNull);
    });

    test('signOut clears the current user session', () async {
      final repository = FakeSessionAuthRepository(currentUser: _user());
      final notifier = SessionNotifier(authRepository: repository);
      addTearDown(notifier.dispose);
      addTearDown(repository.dispose);

      await Future<void>.delayed(Duration.zero);
      await notifier.signOut();

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.userId, 'guest_user');
      expect(notifier.state.isSigningOut, isFalse);
    });
  });
}

class FakeSessionAuthRepository implements AuthRepository {
  FakeSessionAuthRepository({this.currentUser, this.onReloadCurrentUser});

  UserEntity? currentUser;
  final void Function()? onReloadCurrentUser;
  final StreamController<UserEntity?> _sessionController =
      StreamController<UserEntity?>.broadcast();

  @override
  Future<UserEntity?> getCurrentUser() async => currentUser;

  @override
  Stream<UserEntity?> watchCurrentUser() => _sessionController.stream;

  @override
  Future<void> reloadCurrentUser() async {
    onReloadCurrentUser?.call();
    _sessionController.add(currentUser);
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    _sessionController.add(null);
  }

  Future<void> dispose() async {
    await _sessionController.close();
  }

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
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPassword(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> resendEmailVerification(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendCurrentUserEmailVerification() async {}
}

UserEntity _user({
  String email = 'user@example.com',
  bool isEmailVerified = true,
}) {
  return UserEntity(
    id: 'user-1',
    email: email,
    fullName: 'Tester',
    token: 'token',
    role: UserRoles.user,
    isEmailVerified: isEmailVerified,
  );
}
