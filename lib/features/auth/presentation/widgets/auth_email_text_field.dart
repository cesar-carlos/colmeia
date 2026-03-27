// Auth feature: thin wrappers over shared form primitives (see also
// auth_form_text_field, auth_password_text_field).
import 'package:colmeia/shared/widgets/forms/app_email_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Auth-scoped alias over [AppEmailField].
class AuthEmailTextField extends StatelessWidget {
  const AuthEmailTextField({
    required this.controller,
    super.key,
    this.enabled = true,
    this.label,
    this.icon,
    this.hintText = 'nome@empresa.com',
    this.emptyMessage = 'Informe o e-mail',
    this.invalidMessage = 'Informe um e-mail valido.',
    this.decoration,
    this.density = AppTextFieldDensity.comfortable,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? label;
  final IconData? icon;
  final String hintText;
  final String emptyMessage;
  final String invalidMessage;
  final InputDecoration? decoration;
  final AppTextFieldDensity density;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return AppEmailField(
      controller: controller,
      enabled: enabled,
      label: label,
      prefixIcon: icon,
      hintText: hintText,
      emptyMessage: emptyMessage,
      invalidMessage: invalidMessage,
      decoration: decoration,
      density: density,
      semanticsLabel: semanticsLabel,
    );
  }
}
