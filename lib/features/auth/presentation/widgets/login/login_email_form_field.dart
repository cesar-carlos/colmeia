import 'package:colmeia/features/auth/presentation/widgets/auth_email_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_labeled_field.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class LoginEmailFormField extends StatelessWidget {
  const LoginEmailFormField({
    required this.controller,
    required this.enabled,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LoginLabeledField(
      label: l10n.authLoginEmailLabel,
      icon: Icons.alternate_email_rounded,
      child: AuthEmailTextField(
        controller: controller,
        enabled: enabled,
        emptyMessage: l10n.authEmailFieldRequired,
        invalidMessage: l10n.authEmailFieldInvalid,
        decoration: const InputDecoration(
          hintText: 'nome@empresa.com',
        ),
      ),
    );
  }
}
