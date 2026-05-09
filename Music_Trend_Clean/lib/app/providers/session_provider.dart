import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((
  ref,
) {
  return SessionNotifier(authRepository: ref.read(authRepositoryProvider));
});

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier({required this.authRepository})
    : super(const SessionState.loading()) {
    _sessionSubscription = authRepository.watchCurrentUser().listen(
      _handleSessionChanged,
      onError: _handleSessionError,
    );
    loadCurrentUser(showLoading: false);
  }

  final AuthRepository authRepository;
  StreamSubscription<UserEntity?>? _sessionSubscription;

  Future<void> loadCurrentUser({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }

    try {
      final user = await authRepository.getCurrentUser();
      if (!mounted) {
        return;
      }

      _setCurrentUser(user);
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageMapper.map(error),
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    state = state.copyWith(
      isSendingVerificationEmail: true,
      clearActionErrorMessage: true,
    );

    try {
      await authRepository.sendCurrentUserEmailVerification();
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(actionErrorMessage: ErrorMessageMapper.map(error));
    } finally {
      if (mounted) {
        state = state.copyWith(isSendingVerificationEmail: false);
      }
    }
  }

  Future<void> refreshCurrentUser() async {
    state = state.copyWith(
      isRefreshingCurrentUser: true,
      clearActionErrorMessage: true,
    );

    try {
      await authRepository.reloadCurrentUser();
      final user = await authRepository.getCurrentUser();
      if (!mounted) {
        return;
      }

      _setCurrentUser(user);
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(actionErrorMessage: ErrorMessageMapper.map(error));
    } finally {
      if (mounted) {
        state = state.copyWith(isRefreshingCurrentUser: false);
      }
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isSigningOut: true, clearActionErrorMessage: true);

    try {
      await authRepository.signOut();
      if (!mounted) {
        return;
      }

      state = const SessionState.unauthenticated();
    } catch (error) {
      if (!mounted) {
        return;
      }

      state = state.copyWith(
        isSigningOut: false,
        actionErrorMessage: ErrorMessageMapper.map(error),
      );
    }
  }

  void _handleSessionChanged(UserEntity? user) {
    if (!mounted) {
      return;
    }

    _setCurrentUser(user);
  }

  void _handleSessionError(Object error, StackTrace stackTrace) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: ErrorMessageMapper.map(error),
    );
  }

  void _setCurrentUser(UserEntity? user) {
    state = state.copyWith(
      isLoading: false,
      currentUser: user,
      clearErrorMessage: true,
      clearActionErrorMessage: true,
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }
}

const _sessionNoChange = Object();

class SessionState extends Equatable {
  const SessionState({
    required this.isLoading,
    required this.currentUser,
    required this.errorMessage,
    required this.actionErrorMessage,
    required this.isSendingVerificationEmail,
    required this.isRefreshingCurrentUser,
    required this.isSigningOut,
  });

  const SessionState.loading()
    : this(
        isLoading: true,
        currentUser: null,
        errorMessage: null,
        actionErrorMessage: null,
        isSendingVerificationEmail: false,
        isRefreshingCurrentUser: false,
        isSigningOut: false,
      );

  const SessionState.unauthenticated()
    : this(
        isLoading: false,
        currentUser: null,
        errorMessage: null,
        actionErrorMessage: null,
        isSendingVerificationEmail: false,
        isRefreshingCurrentUser: false,
        isSigningOut: false,
      );

  final bool isLoading;
  final UserEntity? currentUser;
  final String? errorMessage;
  final String? actionErrorMessage;
  final bool isSendingVerificationEmail;
  final bool isRefreshingCurrentUser;
  final bool isSigningOut;

  bool get isAuthenticated => currentUser != null;

  bool get isAdmin => currentUser?.isAdmin ?? false;

  bool get isEmailVerified => currentUser?.isEmailVerified ?? false;

  String get userId => currentUser?.id ?? 'guest_user';

  String get email => currentUser?.email ?? '';

  SessionState copyWith({
    bool? isLoading,
    Object? currentUser = _sessionNoChange,
    Object? errorMessage = _sessionNoChange,
    Object? actionErrorMessage = _sessionNoChange,
    bool? isSendingVerificationEmail,
    bool? isRefreshingCurrentUser,
    bool? isSigningOut,
    bool clearErrorMessage = false,
    bool clearActionErrorMessage = false,
  }) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser == _sessionNoChange
          ? this.currentUser
          : currentUser as UserEntity?,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage == _sessionNoChange
          ? this.errorMessage
          : errorMessage as String?,
      actionErrorMessage: clearActionErrorMessage
          ? null
          : actionErrorMessage == _sessionNoChange
          ? this.actionErrorMessage
          : actionErrorMessage as String?,
      isSendingVerificationEmail:
          isSendingVerificationEmail ?? this.isSendingVerificationEmail,
      isRefreshingCurrentUser:
          isRefreshingCurrentUser ?? this.isRefreshingCurrentUser,
      isSigningOut: isSigningOut ?? this.isSigningOut,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    currentUser,
    errorMessage,
    actionErrorMessage,
    isSendingVerificationEmail,
    isRefreshingCurrentUser,
    isSigningOut,
  ];
}
