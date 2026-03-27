import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

/// Auth-scoped alias over [AppTextField].
class AuthFormTextField extends StatelessWidget {
  const AuthFormTextField({
    required this.controller,
    super.key,
    this.label,
    this.icon,
    this.decoration,
    this.validator,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.autofillHints,
    this.hintText,
    this.density = AppTextFieldDensity.comfortable,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final String? label;
  final IconData? icon;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final String? hintText;
  final AppTextFieldDensity density;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      prefixIcon: icon,
      suffix: suffixIcon,
      decoration: decoration,
      validator: validator,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      density: density,
      semanticsLabel: semanticsLabel,
    );
  }
}
