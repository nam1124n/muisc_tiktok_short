import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:login_flutter/l10n/app_localizations.dart';
import 'package:login_flutter/ui/screen/auth/forgot_password/forgot_password_provider.dart';
import 'package:login_flutter/ui/screen/auth/forgot_password/forgot_password_state.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordNotifierProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(forgotPasswordNotifierProvider.notifier).clearMessage();
      }

      if (next.successMessage != null && next.successMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(forgotPasswordNotifierProvider.notifier).clearMessage();
      }
    });

    final state = ref.watch(forgotPasswordNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: ref
                  .read(forgotPasswordNotifierProvider.notifier)
                  .onEmailChanged,
              decoration: InputDecoration(
                labelText: l10n.emailAddress,
                hintText: 'name@example.com',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: state.status == ForgotPasswordStatus.loading
                  ? null
                  : () {
                      ref
                          .read(forgotPasswordNotifierProvider.notifier)
                          .submit(
                            emailRequiredMessage: l10n.emailRequiredMessage,
                            invalidEmailFormatMessage:
                                l10n.invalidEmailFormatMessage,
                            resetPasswordSentMessage:
                                l10n.resetPasswordSentMessage,
                          );
                    },
              child: state.status == ForgotPasswordStatus.loading
                  ? const CircularProgressIndicator()
                  : Text(l10n.sendResetEmail),
            ),
          ],
        ),
      ),
    );
  }
}
