import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

/// Shared [CircularProgressIndicator] sizing for action buttons (loading).
Widget buildAppActionButtonProgressIndicator({
  required BuildContext context,
  required Color color,
  required double size,
  required double strokeWidth,
}) {
  final disableAnimations =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  return SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      value: disableAnimations ? 1 : null,
      strokeWidth: strokeWidth,
      color: color,
    ),
  );
}

/// Wraps a Material action button with consistent [Semantics] for loading and
/// optional [semanticsLabel].
Widget wrapAppActionButtonSemantics({
  required Widget child,
  required bool isLoading,
  required VoidCallback? onPressed,
  String? semanticsLabel,
  String? labelForLoadingAnnouncement,
}) {
  final enabled = onPressed != null && !isLoading;
  if (semanticsLabel != null) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      excludeSemantics: isLoading,
      child: child,
    );
  }
  if (isLoading) {
    final loadingAnnouncement = labelForLoadingAnnouncement != null
        ? 'Carregando: $labelForLoadingAnnouncement'
        : 'Carregando';
    return Semantics(
      button: true,
      enabled: enabled,
      label: loadingAnnouncement,
      excludeSemantics: true,
      child: child,
    );
  }
  return child;
}

double resolveAppActionButtonRadius(AppThemeTokens? tokens) {
  return (tokens?.formFieldRadius ?? 8) + 2;
}

TextStyle resolveAppActionButtonTextStyle(ThemeData theme) {
  return theme.appTypography.sectionHeaderH2.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );
}

Color resolveAppActionButtonDisabledBackground(ColorScheme scheme) {
  return scheme.surfaceContainerHighest;
}

Color resolveAppActionButtonDisabledForeground(ColorScheme scheme) {
  return scheme.onSurfaceVariant.withValues(alpha: 0.72);
}
