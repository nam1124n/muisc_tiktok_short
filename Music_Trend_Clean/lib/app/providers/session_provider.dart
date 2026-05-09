import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/config/app_config.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';
import 'package:login_flutter/domain/repositories/auth_repository.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((
  ref,
) {
  return SessionNotifier(authRepository: ref.read(authRepositoryProvider));
});

final sessionCurrentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider.select((state) => state.currentUser?.id));
});

final sessionHasAdminAccessProvider = Provider<bool>((ref) {
  final user = ref.watch(sessionProvider.select((state) => state.currentUser));
  if (user == null) {
    return false;
  }

  return user.isAdmin || AppConfig.isAdminEmail(user.email);
});

class SessionNotifier extends StateNotifier<SessionState> {
  static const _terminalSessionMessages = [
    ErrorMessageMapper.sessionExpiredMessage,
    ErrorMessageMapper.accountDisabledMessage,
    ErrorMessageMapper.accountNotFoundMessage,
  ];

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

      _handleStateError(error, isAction: false);
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

      _handleStateError(error, isAction: true);
    } finally {
      if (mounted) {
        state = state.copyWith(isSendingVerificationEmail: false);
      }
    }
  }

  Future<void> refreshCurrentUser({bool reportActionError = true}) async {
    state = state.copyWith(
      isRefreshingCurrentUser: true,
      clearActionErrorMessage: reportActionError,
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

      _handleStateError(
        error,
        isAction: true,
        reportActionError: reportActionError,
      );
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

      _handleStateError(error, isAction: true);
      state = state.copyWith(isSigningOut: false);
    }
  }

  Future<void> handleAppResumed() async {
    if (state.isLoading ||
        state.isRefreshingCurrentUser ||
        state.isSigningOut ||
        state.isSendingVerificationEmail) {
      return;
    }

    if (!state.isAuthenticated) {
      await loadCurrentUser(showLoading: false);
      return;
    }

    await refreshCurrentUser(reportActionError: false);
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

    _handleStateError(error, isAction: false);
  }

  void _setCurrentUser(UserEntity? user) {
    state = state.copyWith(
      isLoading: false,
      currentUser: user,
      clearErrorMessage: true,
      clearActionErrorMessage: true,
    );
  }

  void _handleStateError(
    Object error, {
    required bool isAction,
    bool reportActionError = true,
  }) {
    final message = ErrorMessageMapper.map(error);

    if (_terminalSessionMessages.contains(message)) {
      state = const SessionState.unauthenticated().copyWith(
        errorMessage: message,
      );
      return;
    }

    if (isAction) {
      state = state.copyWith(
        actionErrorMessage: reportActionError ? message : null,
      );
      return;
    }

    state = state.copyWith(isLoading: false, errorMessage: message);
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
