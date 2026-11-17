import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:material_ui/material_ui.dart';

Color resolveAppActionButtonForeground(ColorScheme scheme) =>
    scheme.surfaceAccent;

Color resolveAppActionButtonLoadingColor({
  required ColorScheme scheme,
  required ButtonStyle style,
  required Color fallbackBackground,
  Color? overrideColor,
}) {
  if (overrideColor != null) return overrideColor;
  final background = Color.alphaBlend(
    style.backgroundColor?.resolve({WidgetState.disabled}) ??
        fallbackBackground,
    scheme.surface,
  );
  double contrast(Color color) {
    final foreground = Color.alphaBlend(color, background).computeLuminance();
    final backdrop = background.computeLuminance();
    return foreground > backdrop
        ? (foreground + 0.05) / (backdrop + 0.05)
        : (backdrop + 0.05) / (foreground + 0.05);
  }

  final normal = scheme.onSurface;
  final inverse = scheme.onInverseSurface;
  return contrast(normal) >= 3 || contrast(normal) >= contrast(inverse)
      ? normal
      : inverse;
}

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
