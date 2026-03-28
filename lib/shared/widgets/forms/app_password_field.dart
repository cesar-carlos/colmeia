import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';

class AppPasswordField extends StatelessWidget {
  const AppPasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggleObscure,
    super.key,
    this.enabled = true,
    this.label,
    this.prefixIcon,
    this.hintText = '••••••••',
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
    this.validator,
    this.decoration,
    this.toggleVisibilityTooltipShow = 'Mostrar senha',
    this.toggleVisibilityTooltipHide = 'Ocultar senha',
    this.density = AppTextFieldDensity.comfortable,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final String? label;
  final IconData? prefixIcon;
  final String hintText;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final String toggleVisibilityTooltipShow;
  final String toggleVisibilityTooltipHide;
  final AppTextFieldDensity density;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return AppTextField(
      controller: controller,
      enabled: enabled,
      label: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      decoration: decoration,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: const <String>[AutofillHints.password],
      onFieldSubmitted: onFieldSubmitted,
      validator: validator ?? AppFormValidators.password,
      density: density,
      semanticsLabel: semanticsLabel,
      suffix: IconButton(
        onPressed: onToggleObscure,
        icon: Icon(
          obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20,
        ),
        color: colors.outlineVariant,
        tooltip: obscureText
            ? toggleVisibilityTooltipShow
            : toggleVisibilityTooltipHide,
      ),
    );
  }
}
