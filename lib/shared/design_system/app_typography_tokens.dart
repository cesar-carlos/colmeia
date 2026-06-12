import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:flutter/material.dart';

class AppTypographyTokens extends ThemeExtension<AppTypographyTokens> {
  const AppTypographyTokens({
    required this.displayH1,
    required this.sectionHeaderH2,
    required this.body,
    required this.caption,
    required this.utilityOverline,
  });

  factory AppTypographyTokens.fromTheme({
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return AppTypographyTokens(
      displayH1: (textTheme.displaySmall ?? const TextStyle()).copyWith(
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        color: colorScheme.onSurface,
      ),
      sectionHeaderH2: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        color: colorScheme.onSurface,
      ),
      body: (textTheme.bodyLarge ?? const TextStyle()).copyWith(
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: colorScheme.onSurface,
      ),
      caption: (textTheme.bodySmall ?? const TextStyle()).copyWith(
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.05,
        color: colorScheme.onSurfaceVariant,
      ),
      utilityOverline: (textTheme.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.45,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.92),
      ),
    );
  }

  final TextStyle displayH1;
  final TextStyle sectionHeaderH2;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle utilityOverline;

  static final AppTypographyTokens light = AppTypographyTokens.fromTheme(
    textTheme: ThemeData.light().textTheme,
    colorScheme: AppColors.light.toColorScheme(),
  );

  @override
  AppTypographyTokens copyWith({
    TextStyle? displayH1,
    TextStyle? sectionHeaderH2,
    TextStyle? body,
    TextStyle? caption,
    TextStyle? utilityOverline,
  }) {
    return AppTypographyTokens(
      displayH1: displayH1 ?? this.displayH1,
      sectionHeaderH2: sectionHeaderH2 ?? this.sectionHeaderH2,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      utilityOverline: utilityOverline ?? this.utilityOverline,
    );
  }

  @override
  AppTypographyTokens lerp(
    ThemeExtension<AppTypographyTokens>? other,
    double t,
  ) {
    if (other is! AppTypographyTokens) {
      return this;
    }

    return AppTypographyTokens(
      displayH1: TextStyle.lerp(displayH1, other.displayH1, t) ?? displayH1,
      sectionHeaderH2:
          TextStyle.lerp(sectionHeaderH2, other.sectionHeaderH2, t) ??
          sectionHeaderH2,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
      utilityOverline:
          TextStyle.lerp(utilityOverline, other.utilityOverline, t) ??
          utilityOverline,
    );
  }
}

extension AppTypographyThemeDataX on ThemeData {
  AppTypographyTokens get appTypography =>
      extension<AppTypographyTokens>() ?? AppTypographyTokens.light;
}

extension AppTypographyBuildContextX on BuildContext {
  AppTypographyTokens get appTypography => Theme.of(this).appTypography;
}
