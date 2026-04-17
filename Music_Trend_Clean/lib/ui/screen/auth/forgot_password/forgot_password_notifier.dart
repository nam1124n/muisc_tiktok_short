import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/usecases/reset_password_usecase.dart';
import 'forgot_password_state.dart';

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final ResetPasswordUseCase resetPasswordUseCase;

  ForgotPasswordNotifier(this.resetPasswordUseCase)
    : super(const ForgotPasswordState());

  void onEmailChanged(String value) {
    state = state.copyWith(
      email: value,
      errorMessage: null,
      successMessage: null,
      status: ForgotPasswordStatus.initial,
    );
  }

  Future<void> submit({
    required String emailRequiredMessage,
    required String invalidEmailFormatMessage,
    required String resetPasswordSentMessage,
  }) async {
    final email = state.email.trim();

    if (email.isEmpty) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: emailRequiredMessage,
        successMessage: null,
      );
      return;
    }

    final isValidEmail = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);

    if (!isValidEmail) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: invalidEmailFormatMessage,
        successMessage: null,
      );
      return;
    }

    state = state.copyWith(
      status: ForgotPasswordStatus.loading,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await resetPasswordUseCase(email);
      state = state.copyWith(
        status: ForgotPasswordStatus.success,
        successMessage: resetPasswordSentMessage,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        successMessage: null,
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
