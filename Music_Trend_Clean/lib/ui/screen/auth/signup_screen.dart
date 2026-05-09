import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/domain/entities/profile_entity.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_provider.dart';
import 'package:login_flutter/ui/screen/auth/providers/auth_state.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends ConsumerState<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedAgeGroup;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(authNotifierProvider.notifier);
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final validationMessage = notifier.validateSignUpInput(
      fullName: _nameController.text,
      email: _emailController.text,
      password: password,
      confirmPassword: confirmPassword,
      ageGroup: _selectedAgeGroup,
      fullNameRequiredMessage: l10n.fullNameRequiredMessage,
      emailRequiredMessage: l10n.emailRequiredMessage,
      invalidEmailFormatMessage: l10n.invalidEmailFormatMessage,
      passwordRequiredMessage: l10n.passwordRequiredMessage,
      passwordTooShortMessage: l10n.passwordTooShortMessage,
      passwordWeakMessage: l10n.passwordWeakMessage,
      passwordsDoNotMatchMessage: l10n.passwordsDoNotMatch,
      ageGroupRequiredMessage: l10n.ageGroupRequiredMessage,
    );

    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage), backgroundColor: Colors.red),
      );
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .signUp(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: password,
          ageGroup: _selectedAgeGroup!,
        );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.message), backgroundColor: Colors.red),
      );
    } else if (authState is AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.verificationEmailSentMessage),
          backgroundColor: Colors.green,
        ),
      );
      ref.read(authNotifierProvider.notifier).reset();
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String hintText, {TextStyle? hintStyle}) {
    return InputDecoration(hintText: hintText, hintStyle: hintStyle);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 48.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  l10n.createAccountTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createAccountSubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel(l10n.fullNameLabel.toUpperCase()),
                        const SizedBox(height: 8),
                        _buildTextField('John Doe', false, _nameController),
                        const SizedBox(height: 20),
                        _buildLabel(l10n.emailAddress.toUpperCase()),
                        const SizedBox(height: 8),
                        _buildTextField(
                          'name@example.com',
                          false,
                          _emailController,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel(l10n.password.toUpperCase()),
                        const SizedBox(height: 8),
                        _buildTextField('••••••••', true, _passwordController),
                        const SizedBox(height: 8),
                        Text(
                          l10n.passwordRequirementHint,
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel(l10n.confirmPasswordLabel.toUpperCase()),
                        const SizedBox(height: 8),
                        _buildTextField(
                          '••••••••',
                          true,
                          _confirmPasswordController,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel(l10n.ageGroupLabel.toUpperCase()),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAgeGroup,
                          decoration: _inputDecoration(l10n.selectAgeGroupHint),
                          items: ProfileAgeGroups.values
                              .map(
                                (ageGroup) => DropdownMenuItem(
                                  value: ageGroup,
                                  child: Text(_ageGroupLabel(l10n, ageGroup)),
                                ),
                              )
                              .toList(),
                          onChanged: state is AuthLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedAgeGroup = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: state is AuthLoading ? null : _signUp,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  l10n.signUp,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${l10n.alreadyHaveAccount} ',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.backToLogin,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.labelMedium);
  }

  Widget _buildTextField(
    String hint,
    bool isPassword,
    TextEditingController controller,
  ) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: _inputDecoration(
        hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey[400],
          letterSpacing: isPassword ? 4 : null,
        ),
      ),
    );
  }

  String _ageGroupLabel(AppLocalizations l10n, String ageGroup) {
    switch (ageGroup) {
      case ProfileAgeGroups.under13:
        return l10n.ageGroupUnder13;
      case ProfileAgeGroups.teens:
        return l10n.ageGroupTeens;
      case ProfileAgeGroups.adults:
        return l10n.ageGroupAdults;
      default:
        return l10n.ageGroupPreferNotToSay;
    }
  }
}
