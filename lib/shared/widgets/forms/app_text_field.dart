import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual density for [AppTextField] padding (theme tokens).
enum AppTextFieldDensity {
  comfortable,
  compact,
}

/// Base text field: theme-driven [InputDecoration], optional label/icons/suffix.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    super.key,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.decoration,
    this.validator,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofillHints,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.density = AppTextFieldDensity.comfortable,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final AppTextFieldDensity density;

  /// Screen-reader label when the visible label is not on the input.
  final String? semanticsLabel;

  EdgeInsets _contentPaddingForDensity(AppThemeTokens? tokens) {
    final horizontal = tokens?.formFieldPaddingHorizontal ?? 16;
    final vertical = density == AppTextFieldDensity.compact
        ? (tokens?.formFieldPaddingVerticalCompact ?? 12)
        : (tokens?.formFieldPaddingVerticalComfortable ?? 16);
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  Widget? _buildPrefixWidget(BuildContext context) {
    if (prefix != null) {
      return prefix;
    }
    if (prefixIcon == null) {
      return null;
    }

    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, end: 8),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            prefixIcon,
            size: 18,
            color: enabled
                ? colors.onSurfaceVariant
                : colors.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixWidget() {
    if (suffix == null) {
      return null;
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: suffix,
      ),
    );
  }

  InputDecoration _resolveDecoration(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final densityPadding = _contentPaddingForDensity(tokens);
    final prefixWidget = _buildPrefixWidget(context);
    final suffixWidget = _buildSuffixWidget();
    const iconConstraints = BoxConstraints(minWidth: 52);

    if (decoration != null) {
      return decoration!.copyWith(
        labelText: decoration!.labelText ?? label,
        hintText: decoration!.hintText ?? hintText,
        prefixIcon: decoration!.prefixIcon ?? prefixWidget,
        suffixIcon: decoration!.suffixIcon ?? suffixWidget,
        contentPadding: decoration!.contentPadding ?? densityPadding,
        prefixIconConstraints:
            decoration!.prefixIconConstraints ?? iconConstraints,
        suffixIconConstraints:
            decoration!.suffixIconConstraints ?? iconConstraints,
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixWidget,
      suffixIcon: suffixWidget,
      contentPadding: densityPadding,
      prefixIconConstraints: iconConstraints,
      suffixIconConstraints: iconConstraints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: _resolveDecoration(context),
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      readOnly: readOnly,
      autofocus: autofocus,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
    );

    if (semanticsLabel == null) {
      return field;
    }

    return Semantics(
      label: semanticsLabel,
      child: field,
    );
  }
}
