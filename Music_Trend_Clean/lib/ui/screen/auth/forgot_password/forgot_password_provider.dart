import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/usecases/reset_password_usecase.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/forgot_password/forgot_password_notifier.dart';
import 'package:login_flutter/ui/screen/auth/forgot_password/forgot_password_state.dart';

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.read(authRepositoryProvider));
});

final forgotPasswordNotifierProvider =
    StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>((ref) {
      return ForgotPasswordNotifier(ref.read(resetPasswordUseCaseProvider));
    });
