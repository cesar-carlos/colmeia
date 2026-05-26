import 'package:colmeia/features/auth/presentation/widgets/auth_password_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_labeled_field.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:flutter/material.dart';

class LoginPasswordFormField extends StatelessWidget {
  const LoginPasswordFormField({
    required this.controller,
    required this.obscure,
    required this.enabled,
    required this.onToggleObscure,
    required this.onSubmitted,
    super.key,
    this.onForgot,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggleObscure;
  final VoidCallback? onForgot;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final forgot = onForgot;
    final trailing = forgot == null
        ? null
        : _ForgotPasswordLink(onPressed: forgot);

    return LoginLabeledField(
      label: l10n.authLoginPasswordLabel,
      icon: Icons.lock_outline_rounded,
      trailing: trailing,
      child: AuthPasswordTextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        onToggleObscure: onToggleObscure,
        onFieldSubmitted: (_) => onSubmitted(),
        decoration: const InputDecoration(
          hintText: '••••••••',
        ),
        validator: (value) => AppFormValidators.requiredText(
          value,
          message: l10n.authLoginPasswordRequired,
        ),
      ),
    );
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: cs.secondary,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        l10n.authLoginForgotPasswordShort,
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.secondary,
        ),
      ),
    );
  }
}
