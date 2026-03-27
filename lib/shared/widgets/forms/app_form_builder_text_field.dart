import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// [FormBuilderTextField] aligned with [AppTextField] padding tokens and theme.
class AppFormBuilderTextField extends StatelessWidget {
  const AppFormBuilderTextField({
    required this.name,
    super.key,
    this.label,
    this.hintText,
    this.initialValue,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.readOnly = false,
    this.enabled = true,
    this.autovalidateMode,
    this.density = AppTextFieldDensity.comfortable,
  });

  final String name;
  final String? label;
  final String? hintText;
  final String? initialValue;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final AppTextFieldDensity density;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final horizontal = tokens?.formFieldPaddingHorizontal ?? 16;
    final vertical = density == AppTextFieldDensity.compact
        ? (tokens?.formFieldPaddingVerticalCompact ?? 12)
        : (tokens?.formFieldPaddingVerticalComfortable ?? 16);

    return FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autovalidateMode: autovalidateMode,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
      ),
    );
  }
}
