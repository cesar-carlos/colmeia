import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.error,
    required this.errorContainer,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.inverseSurface,
    required this.onBackground,
    required this.onError,
    required this.onErrorContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.onPrimaryFixed,
    required this.onPrimaryFixedVariant,
    required this.onSecondary,
    required this.onSecondaryContainer,
    required this.onSecondaryFixed,
    required this.onSecondaryFixedVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onTertiary,
    required this.onTertiaryContainer,
    required this.onTertiaryFixed,
    required this.onTertiaryFixedVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.primaryContainer,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.secondary,
    required this.secondaryContainer,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.surface,
    required this.surfaceBright,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceContainerLow,
    required this.surfaceContainerLowest,
    required this.surfaceDim,
    required this.surfaceTint,
    required this.surfaceVariant,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.tertiaryFixed,
    required this.tertiaryFixedDim,
  });

  final Brightness brightness;
  final Color background;
  final Color error;
  final Color errorContainer;
  final Color inverseOnSurface;
  final Color inversePrimary;
  final Color inverseSurface;
  final Color onBackground;
  final Color onError;
  final Color onErrorContainer;
  final Color onPrimary;
  final Color onPrimaryContainer;
  final Color onPrimaryFixed;
  final Color onPrimaryFixedVariant;
  final Color onSecondary;
  final Color onSecondaryContainer;
  final Color onSecondaryFixed;
  final Color onSecondaryFixedVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onTertiary;
  final Color onTertiaryContainer;
  final Color onTertiaryFixed;
  final Color onTertiaryFixedVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color primaryContainer;
  final Color primaryFixed;
  final Color primaryFixedDim;
  final Color secondary;
  final Color secondaryContainer;
  final Color secondaryFixed;
  final Color secondaryFixedDim;
  final Color surface;
  final Color surfaceBright;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceContainerLow;
  final Color surfaceContainerLowest;
  final Color surfaceDim;
  final Color surfaceTint;
  final Color surfaceVariant;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color tertiaryFixed;
  final Color tertiaryFixedDim;

  /// Hive Grid palette sourced from Stitch asset `assets/c7a6171e17c644be86621d551b675f2c`.
  static const AppColors light = AppColors(
    brightness: Brightness.light,
    background: Color(0xFFF4FAFF),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    inverseOnSurface: Color(0xFFE6F3FB),
    inversePrimary: Color(0xFFFFBA38),
    inverseSurface: Color(0xFF263238),
    onBackground: Color(0xFF111D23),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFF93000A),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF6B4900),
    onPrimaryFixed: Color(0xFF281900),
    onPrimaryFixedVariant: Color(0xFF604100),
    onSecondary: Color(0xFF1C0F08),
    onSecondaryContainer: Color(0xFF562100),
    onSecondaryFixed: Color(0xFF341100),
    onSecondaryFixedVariant: Color(0xFF793100),
    onSurface: Color(0xFF111D23),
    onSurfaceVariant: Color(0xFF514532),
    onTertiary: Color(0xFFFFFFFF),
    onTertiaryContainer: Color(0xFF00566A),
    onTertiaryFixed: Color(0xFF001F28),
    onTertiaryFixedVariant: Color(0xFF004E60),
    outline: Color(0xFF847560),
    outlineVariant: Color(0xFFD6C4AC),
    primary: Color(0xFF7E5700),
    primaryContainer: Color(0xFFFFB300),
    primaryFixed: Color(0xFFFFDEAC),
    primaryFixedDim: Color(0xFFFFBA38),
    secondary: Color(0xFF9E4200),
    secondaryContainer: Color(0xFFFB6D00),
    secondaryFixed: Color(0xFFFFDBCB),
    secondaryFixedDim: Color(0xFFFFB691),
    surface: Color(0xFFF4FAFF),
    surfaceBright: Color(0xFFF4FAFF),
    surfaceContainer: Color(0xFFE3F0F8),
    surfaceContainerHigh: Color(0xFFDDEAF2),
    surfaceContainerHighest: Color(0xFFD7E4EC),
    surfaceContainerLow: Color(0xFFE9F6FD),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceDim: Color(0xFFCFDCE4),
    surfaceTint: Color(0xFF7E5700),
    surfaceVariant: Color(0xFFD7E4EC),
    tertiary: Color(0xFF00677E),
    tertiaryContainer: Color(0xFF00D2FE),
    tertiaryFixed: Color(0xFFB5EBFF),
    tertiaryFixedDim: Color(0xFF43D6FF),
  );

  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    background: Color(0xFF263238),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    inverseOnSurface: Color(0xFF111D23),
    inversePrimary: Color(0xFF7E5700),
    inverseSurface: Color(0xFFF4FAFF),
    onBackground: Color(0xFFE6F3FB),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFF93000A),
    onPrimary: Color(0xFF402D00),
    onPrimaryContainer: Color(0xFFFFDEAC),
    onPrimaryFixed: Color(0xFF281900),
    onPrimaryFixedVariant: Color(0xFF604100),
    onSecondary: Color(0xFF562100),
    onSecondaryContainer: Color(0xFFFFDBCB),
    onSecondaryFixed: Color(0xFF341100),
    onSecondaryFixedVariant: Color(0xFF793100),
    onSurface: Color(0xFFE6F3FB),
    onSurfaceVariant: Color(0xFFB0BEC5),
    onTertiary: Color(0xFF003544),
    onTertiaryContainer: Color(0xFFB5EBFF),
    onTertiaryFixed: Color(0xFF001F28),
    onTertiaryFixedVariant: Color(0xFF004E60),
    outline: Color(0xFF9DACB3),
    outlineVariant: Color(0xFF5F6B73),
    primary: Color(0xFFFFBA38),
    primaryContainer: Color(0xFF7E5700),
    primaryFixed: Color(0xFFFFDEAC),
    primaryFixedDim: Color(0xFFFFBA38),
    secondary: Color(0xFFFFB691),
    secondaryContainer: Color(0xFF6B381F),
    secondaryFixed: Color(0xFFFFDBCB),
    secondaryFixedDim: Color(0xFFFFB691),
    surface: Color(0xFF263238),
    surfaceBright: Color(0xFF2E3B41),
    surfaceContainer: Color(0xFF252F35),
    surfaceContainerHigh: Color(0xFF2B363D),
    surfaceContainerHighest: Color(0xFF313D45),
    surfaceContainerLow: Color(0xFF1F282E),
    surfaceContainerLowest: Color(0xFF131B1F),
    surfaceDim: Color(0xFF1B2327),
    surfaceTint: Color(0xFFFFBA38),
    surfaceVariant: Color(0xFF313D45),
    tertiary: Color(0xFF43D6FF),
    tertiaryContainer: Color(0xFF00677E),
    tertiaryFixed: Color(0xFFB5EBFF),
    tertiaryFixedDim: Color(0xFF43D6FF),
  );

  ColorScheme toColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryContainer,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceTint: surfaceTint,
      outline: outline,
      outlineVariant: outlineVariant,
      surfaceBright: surfaceBright,
      surfaceDim: surfaceDim,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
    );
  }

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? error,
    Color? errorContainer,
    Color? inverseOnSurface,
    Color? inversePrimary,
    Color? inverseSurface,
    Color? onBackground,
    Color? onError,
    Color? onErrorContainer,
    Color? onPrimary,
    Color? onPrimaryContainer,
    Color? onPrimaryFixed,
    Color? onPrimaryFixedVariant,
    Color? onSecondary,
    Color? onSecondaryContainer,
    Color? onSecondaryFixed,
    Color? onSecondaryFixedVariant,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? onTertiary,
    Color? onTertiaryContainer,
    Color? onTertiaryFixed,
    Color? onTertiaryFixedVariant,
    Color? outline,
    Color? outlineVariant,
    Color? primary,
    Color? primaryContainer,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? secondary,
    Color? secondaryContainer,
    Color? secondaryFixed,
    Color? secondaryFixedDim,
    Color? surface,
    Color? surfaceBright,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? surfaceContainerLow,
    Color? surfaceContainerLowest,
    Color? surfaceDim,
    Color? surfaceTint,
    Color? surfaceVariant,
    Color? tertiary,
    Color? tertiaryContainer,
    Color? tertiaryFixed,
    Color? tertiaryFixedDim,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      inverseOnSurface: inverseOnSurface ?? this.inverseOnSurface,
      inversePrimary: inversePrimary ?? this.inversePrimary,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onBackground: onBackground ?? this.onBackground,
      onError: onError ?? this.onError,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      onPrimaryFixedVariant:
          onPrimaryFixedVariant ?? this.onPrimaryFixedVariant,
      onSecondary: onSecondary ?? this.onSecondary,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
      onSecondaryFixedVariant:
          onSecondaryFixedVariant ?? this.onSecondaryFixedVariant,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      onTertiary: onTertiary ?? this.onTertiary,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      onTertiaryFixed: onTertiaryFixed ?? this.onTertiaryFixed,
      onTertiaryFixedVariant:
          onTertiaryFixedVariant ?? this.onTertiaryFixedVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      secondaryFixedDim: secondaryFixedDim ?? this.secondaryFixedDim,
      surface: surface ?? this.surface,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      tertiary: tertiary ?? this.tertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
      tertiaryFixedDim: tertiaryFixedDim ?? this.tertiaryFixedDim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }

    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t) ?? background,
      error: Color.lerp(error, other.error, t) ?? error,
      errorContainer:
          Color.lerp(errorContainer, other.errorContainer, t) ?? errorContainer,
      inverseOnSurface:
          Color.lerp(inverseOnSurface, other.inverseOnSurface, t) ??
          inverseOnSurface,
      inversePrimary:
          Color.lerp(inversePrimary, other.inversePrimary, t) ?? inversePrimary,
      inverseSurface:
          Color.lerp(inverseSurface, other.inverseSurface, t) ?? inverseSurface,
      onBackground:
          Color.lerp(onBackground, other.onBackground, t) ?? onBackground,
      onError: Color.lerp(onError, other.onError, t) ?? onError,
      onErrorContainer:
          Color.lerp(onErrorContainer, other.onErrorContainer, t) ??
          onErrorContainer,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t) ??
          onPrimaryContainer,
      onPrimaryFixed:
          Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t) ?? onPrimaryFixed,
      onPrimaryFixedVariant:
          Color.lerp(
            onPrimaryFixedVariant,
            other.onPrimaryFixedVariant,
            t,
          ) ??
          onPrimaryFixedVariant,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t) ?? onSecondary,
      onSecondaryContainer:
          Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t) ??
          onSecondaryContainer,
      onSecondaryFixed:
          Color.lerp(onSecondaryFixed, other.onSecondaryFixed, t) ??
          onSecondaryFixed,
      onSecondaryFixedVariant:
          Color.lerp(
            onSecondaryFixedVariant,
            other.onSecondaryFixedVariant,
            t,
          ) ??
          onSecondaryFixedVariant,
      onSurface: Color.lerp(onSurface, other.onSurface, t) ?? onSurface,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t) ??
          onSurfaceVariant,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t) ?? onTertiary,
      onTertiaryContainer:
          Color.lerp(onTertiaryContainer, other.onTertiaryContainer, t) ??
          onTertiaryContainer,
      onTertiaryFixed:
          Color.lerp(onTertiaryFixed, other.onTertiaryFixed, t) ??
          onTertiaryFixed,
      onTertiaryFixedVariant:
          Color.lerp(
            onTertiaryFixedVariant,
            other.onTertiaryFixedVariant,
            t,
          ) ??
          onTertiaryFixedVariant,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      outlineVariant:
          Color.lerp(outlineVariant, other.outlineVariant, t) ?? outlineVariant,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t) ??
          primaryContainer,
      primaryFixed:
          Color.lerp(primaryFixed, other.primaryFixed, t) ?? primaryFixed,
      primaryFixedDim:
          Color.lerp(primaryFixedDim, other.primaryFixedDim, t) ??
          primaryFixedDim,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t) ??
          secondaryContainer,
      secondaryFixed:
          Color.lerp(secondaryFixed, other.secondaryFixed, t) ?? secondaryFixed,
      secondaryFixedDim:
          Color.lerp(secondaryFixedDim, other.secondaryFixedDim, t) ??
          secondaryFixedDim,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceBright:
          Color.lerp(surfaceBright, other.surfaceBright, t) ?? surfaceBright,
      surfaceContainer:
          Color.lerp(surfaceContainer, other.surfaceContainer, t) ??
          surfaceContainer,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t) ??
          surfaceContainerHigh,
      surfaceContainerHighest:
          Color.lerp(
            surfaceContainerHighest,
            other.surfaceContainerHighest,
            t,
          ) ??
          surfaceContainerHighest,
      surfaceContainerLow:
          Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t) ??
          surfaceContainerLow,
      surfaceContainerLowest:
          Color.lerp(
            surfaceContainerLowest,
            other.surfaceContainerLowest,
            t,
          ) ??
          surfaceContainerLowest,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t) ?? surfaceDim,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t) ?? surfaceTint,
      surfaceVariant:
          Color.lerp(surfaceVariant, other.surfaceVariant, t) ?? surfaceVariant,
      tertiary: Color.lerp(tertiary, other.tertiary, t) ?? tertiary,
      tertiaryContainer:
          Color.lerp(tertiaryContainer, other.tertiaryContainer, t) ??
          tertiaryContainer,
      tertiaryFixed:
          Color.lerp(tertiaryFixed, other.tertiaryFixed, t) ?? tertiaryFixed,
      tertiaryFixedDim:
          Color.lerp(tertiaryFixedDim, other.tertiaryFixedDim, t) ??
          tertiaryFixedDim,
    );
  }
}

extension AppColorsThemeDataX on ThemeData {
  AppColors get appColors => extension<AppColors>()!;
}

extension AppColorsBuildContextX on BuildContext {
  AppColors get appColors => Theme.of(this).appColors;
}
