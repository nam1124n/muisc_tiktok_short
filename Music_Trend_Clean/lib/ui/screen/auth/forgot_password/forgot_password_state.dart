enum ForgotPasswordStatus { initial, loading, success, error }

class ForgotPasswordState {
  final String email;
  final ForgotPasswordStatus status;
  final String? errorMessage;
  final String? successMessage;

  const ForgotPasswordState({
    this.email = '',
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  ForgotPasswordState copyWith({
    String? email,
    ForgotPasswordStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
