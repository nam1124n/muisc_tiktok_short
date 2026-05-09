import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/app/utils/auth_input_validator.dart';
import 'package:login_flutter/app/utils/error_message_mapper.dart';
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
    final validationMessage = AuthInputValidator.validateEmail(
      email: state.email,
      emailRequiredMessage: emailRequiredMessage,
      invalidEmailFormatMessage: invalidEmailFormatMessage,
    );
    if (validationMessage != null) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: validationMessage,
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
      await resetPasswordUseCase(state.email.trim());
      state = state.copyWith(
        status: ForgotPasswordStatus.success,
        successMessage: resetPasswordSentMessage,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: ErrorMessageMapper.map(e),
        successMessage: null,
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
