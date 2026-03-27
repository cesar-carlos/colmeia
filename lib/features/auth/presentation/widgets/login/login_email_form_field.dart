import 'package:colmeia/features/auth/presentation/widgets/auth_email_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_labeled_field.dart';
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
    return LoginLabeledField(
      label: 'Usuário ou e-mail',
      icon: Icons.alternate_email_rounded,
      child: AuthEmailTextField(
        controller: controller,
        enabled: enabled,
        decoration: const InputDecoration(
          hintText: 'nome@empresa.com',
        ),
      ),
    );
  }
}
