import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

enum AppStatusBadgeVariant {
  neutral,
  info,
  success,
  warning,
  error,
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    super.key,
    this.variant = AppStatusBadgeVariant.neutral,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final AppStatusBadgeVariant variant;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final palette = _resolvePalette(cs);
    final resolvedForeground = foregroundColor ?? palette.foreground;
    final resolvedBackground = backgroundColor ?? palette.background;
    final resolvedBorder =
        borderColor ??
        palette.border ??
        resolvedForeground.withValues(alpha: 0.16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 10),
        border: Border.all(color: resolvedBorder),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          style: typography.utilityOverline.copyWith(
            color: resolvedForeground,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  ({Color foreground, Color background, Color? border}) _resolvePalette(
    ColorScheme cs,
  ) {
    return switch (variant) {
      AppStatusBadgeVariant.info => (
        foreground: cs.onPrimaryContainer,
        background: cs.primaryContainer,
        border: cs.primary.withValues(alpha: 0.18),
      ),
      AppStatusBadgeVariant.success => (
        foreground: cs.onTertiaryContainer,
        background: cs.tertiaryContainer,
        border: cs.tertiary.withValues(alpha: 0.18),
      ),
      AppStatusBadgeVariant.warning => (
        foreground: cs.onSecondaryContainer,
        background: cs.secondaryContainer,
        border: cs.secondary.withValues(alpha: 0.18),
      ),
      AppStatusBadgeVariant.error => (
        foreground: cs.onErrorContainer,
        background: cs.errorContainer,
        border: cs.error.withValues(alpha: 0.18),
      ),
      AppStatusBadgeVariant.neutral => (
        foreground: cs.onSurfaceVariant,
        background: cs.surfaceContainerHighest.withValues(alpha: 0.72),
        border: cs.outlineVariant.withValues(alpha: 0.4),
      ),
    };
  }
}
