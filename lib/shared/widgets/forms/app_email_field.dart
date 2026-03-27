import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

class AppEmailField extends StatelessWidget {
  const AppEmailField({
    required this.controller,
    super.key,
    this.enabled = true,
    this.label,
    this.prefixIcon,
    this.hintText = 'nome@empresa.com',
    this.emptyMessage = 'Informe o e-mail',
    this.invalidMessage = 'Informe um e-mail valido.',
    this.decoration,
    this.suffix,
    this.onFieldSubmitted,
    this.autofillHints = const <String>[AutofillHints.username],
    this.density = AppTextFieldDensity.comfortable,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? label;
  final IconData? prefixIcon;
  final String hintText;
  final String emptyMessage;
  final String invalidMessage;
  final InputDecoration? decoration;
  final Widget? suffix;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final AppTextFieldDensity density;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      enabled: enabled,
      label: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffix: suffix,
      decoration: decoration,
      keyboardType: TextInputType.emailAddress,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      density: density,
      semanticsLabel: semanticsLabel,
      validator: (value) => AppFormValidators.email(
        value,
        emptyMessage: emptyMessage,
        invalidMessage: invalidMessage,
      ),
    );
  }
}
