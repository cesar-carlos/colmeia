import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

/// Inline helper/error message shown below custom form fields
/// (`AppDropdownField`, `AppDatePickerField`, `AppSliderField`).
///
/// [errorText] takes precedence over [helperText]; when both are empty the
/// widget collapses to zero size.
class AppFormFieldMessage extends StatelessWidget {
  const AppFormFieldMessage({
    required this.helperText,
    required this.errorText,
    super.key,
  });

  final String? helperText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final message = errorText ?? helperText;
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
        top: tokens.gapXs,
        left: tokens.gapXs,
      ),
      child: Text(
        message,
        style: theme.appTypography.caption.copyWith(
          color: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Resolves the border color for custom form-field containers based on state.
///
/// [focused] covers both an open overlay (dropdown/date picker) and an active
/// focus, which share the same emphasized border treatment.
BorderSide resolveFormFieldBorderSide({
  required AppColors colors,
  required ColorScheme scheme,
  required bool enabled,
  required bool focused,
  required bool hasError,
}) {
  if (!enabled) {
    return BorderSide(color: colors.onSurface.withValues(alpha: 0.12));
  }
  if (hasError) {
    return BorderSide(color: scheme.error, width: 1.5);
  }
  if (focused) {
    return BorderSide(color: scheme.primary, width: 1.5);
  }
  return BorderSide(color: colors.outlineVariant.withValues(alpha: 0.82));
}
