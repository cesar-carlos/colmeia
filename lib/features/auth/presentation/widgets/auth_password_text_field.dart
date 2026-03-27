import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:colmeia/shared/widgets/forms/app_password_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Auth-scoped alias over [AppPasswordField].
class AuthPasswordTextField extends StatelessWidget {
  const AuthPasswordTextField({
    required this.controller,
    required this.obscureText,
    required this.onToggleObscure,
    super.key,
    this.enabled = true,
    this.label,
    this.icon,
    this.hintText = '••••••••',
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
    this.validator,
    this.decoration,
    this.density = AppTextFieldDensity.comfortable,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final String? label;
  final IconData? icon;
  final String hintText;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final AppTextFieldDensity density;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return AppPasswordField(
      controller: controller,
      obscureText: obscureText,
      onToggleObscure: onToggleObscure,
      enabled: enabled,
      label: label,
      prefixIcon: icon,
      hintText: hintText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator ?? AppFormValidators.password,
      decoration: decoration,
      density: density,
      semanticsLabel: semanticsLabel,
    );
  }
}
