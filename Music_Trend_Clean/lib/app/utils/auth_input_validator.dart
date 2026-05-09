class AuthInputValidator {
  static final RegExp emailPattern = RegExp(
    r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
  );
  static final RegExp hasUppercase = RegExp(r'[A-Z]');
  static final RegExp hasLowercase = RegExp(r'[a-z]');
  static final RegExp hasDigit = RegExp(r'\d');
  static final RegExp hasSpecialCharacter = RegExp(
    r'''[!@#$%^&*(),.?":{}|<>\[\]_\-+=/\\;']''',
  );

  static String? validateEmail({
    required String email,
    required String emailRequiredMessage,
    required String invalidEmailFormatMessage,
  }) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return emailRequiredMessage;
    }

    if (!emailPattern.hasMatch(trimmedEmail)) {
      return invalidEmailFormatMessage;
    }

    return null;
  }

  static String? validateLogin({
    required String email,
    required String password,
    required String emailRequiredMessage,
    required String invalidEmailFormatMessage,
    required String passwordRequiredMessage,
  }) {
    final emailValidation = validateEmail(
      email: email,
      emailRequiredMessage: emailRequiredMessage,
      invalidEmailFormatMessage: invalidEmailFormatMessage,
    );
    if (emailValidation != null) {
      return emailValidation;
    }

    if (password.trim().isEmpty) {
      return passwordRequiredMessage;
    }

    return null;
  }

  static String? validateSignUp({
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

    final loginValidation = validateLogin(
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
        hasUppercase.hasMatch(password) &&
        hasLowercase.hasMatch(password) &&
        hasDigit.hasMatch(password) &&
        hasSpecialCharacter.hasMatch(password);
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
