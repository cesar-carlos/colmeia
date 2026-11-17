// Third-party widgets still read Flutter's legacy Material theme.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart' as legacy;
import 'package:material_ui/material_ui.dart';

class AppLegacyMaterialTheme extends StatelessWidget {
  const AppLegacyMaterialTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => legacy.Theme(
    data: buildLegacyMaterialTheme(Theme.of(context)),
    child: child,
  );
}

legacy.ThemeData buildLegacyMaterialTheme(ThemeData theme) {
  final colors = theme.colorScheme;
  final text = theme.textTheme;
  return legacy.ThemeData(
    brightness: theme.brightness,
    useMaterial3: theme.useMaterial3,
    platform: theme.platform,
    scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
    cardColor: theme.cardColor,
    dividerColor: theme.dividerColor,
    disabledColor: theme.disabledColor,
    colorScheme: legacy.ColorScheme(
      brightness: colors.brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.onErrorContainer,
      surface: colors.surface,
      onSurface: colors.onSurface,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      shadow: colors.shadow,
      scrim: colors.scrim,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.onInverseSurface,
      inversePrimary: colors.inversePrimary,
      surfaceTint: colors.surfaceTint,
      surfaceDim: colors.surfaceDim,
      surfaceBright: colors.surfaceBright,
      surfaceContainerLowest: colors.surfaceContainerLowest,
      surfaceContainerLow: colors.surfaceContainerLow,
      surfaceContainer: colors.surfaceContainer,
      surfaceContainerHigh: colors.surfaceContainerHigh,
      surfaceContainerHighest: colors.surfaceContainerHighest,
      primaryFixed: colors.primaryFixed,
      primaryFixedDim: colors.primaryFixedDim,
      onPrimaryFixed: colors.onPrimaryFixed,
      onPrimaryFixedVariant: colors.onPrimaryFixedVariant,
      secondaryFixed: colors.secondaryFixed,
      secondaryFixedDim: colors.secondaryFixedDim,
      onSecondaryFixed: colors.onSecondaryFixed,
      onSecondaryFixedVariant: colors.onSecondaryFixedVariant,
      tertiaryFixed: colors.tertiaryFixed,
      tertiaryFixedDim: colors.tertiaryFixedDim,
      onTertiaryFixed: colors.onTertiaryFixed,
      onTertiaryFixedVariant: colors.onTertiaryFixedVariant,
    ),
    textTheme: legacy.TextTheme(
      displayLarge: text.displayLarge,
      displayMedium: text.displayMedium,
      displaySmall: text.displaySmall,
      headlineLarge: text.headlineLarge,
      headlineMedium: text.headlineMedium,
      headlineSmall: text.headlineSmall,
      titleLarge: text.titleLarge,
      titleMedium: text.titleMedium,
      titleSmall: text.titleSmall,
      bodyLarge: text.bodyLarge,
      bodyMedium: text.bodyMedium,
      bodySmall: text.bodySmall,
      labelLarge: text.labelLarge,
      labelMedium: text.labelMedium,
      labelSmall: text.labelSmall,
    ),
  );
}
