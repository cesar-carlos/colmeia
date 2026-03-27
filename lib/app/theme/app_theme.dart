import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static final _HiveGridPalette _palette = _HiveGridPalette();

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _palette.lightPrimaryContainer,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: _palette.lightPrimary,
          onPrimary: _palette.onPrimary,
          primaryContainer: _palette.lightPrimaryContainer,
          onPrimaryContainer: _palette.onPrimaryContainer,
          secondary: _palette.lightSecondary,
          onSecondary: _palette.onSecondary,
          secondaryContainer: _palette.lightSecondaryContainer,
          onSecondaryContainer: _palette.onSecondaryContainer,
          tertiary: _palette.lightTertiary,
          onTertiary: _palette.onTertiary,
          tertiaryContainer: _palette.lightTertiaryContainer,
          onTertiaryContainer: _palette.onTertiaryContainer,
          error: _palette.error,
          onError: _palette.onError,
          errorContainer: _palette.errorContainer,
          onErrorContainer: _palette.onErrorContainer,
          surface: _palette.surface,
          onSurface: _palette.onSurface,
          onSurfaceVariant: _palette.onSurfaceVariant,
          surfaceTint: _palette.lightPrimary,
          outline: _palette.outline,
          outlineVariant: _palette.outlineVariant,
          surfaceBright: _palette.surfaceBright,
          surfaceDim: _palette.surfaceDim,
          surfaceContainerLowest: _palette.surfaceContainerLowest,
          surfaceContainerLow: _palette.surfaceContainerLow,
          surfaceContainer: _palette.surfaceContainer,
          surfaceContainerHigh: _palette.surfaceContainerHigh,
          surfaceContainerHighest: _palette.surfaceContainerHighest,
          inverseSurface: _palette.inverseSurface,
          onInverseSurface: _palette.inverseOnSurface,
          inversePrimary: _palette.inversePrimary,
        );

    return _buildTheme(colorScheme, AppThemeTokens.light);
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _palette.lightPrimaryContainer,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: _palette.darkPrimary,
          onPrimary: _palette.darkOnPrimary,
          primaryContainer: _palette.darkPrimaryContainer,
          onPrimaryContainer: _palette.darkOnPrimaryContainer,
          secondary: _palette.darkSecondary,
          onSecondary: _palette.darkOnSecondary,
          secondaryContainer: _palette.darkSecondaryContainer,
          onSecondaryContainer: _palette.darkOnSecondaryContainer,
          tertiary: _palette.darkTertiary,
          onTertiary: _palette.darkOnTertiary,
          tertiaryContainer: _palette.darkTertiaryContainer,
          onTertiaryContainer: _palette.darkOnTertiaryContainer,
          error: _palette.error,
          onError: _palette.onError,
          errorContainer: _palette.errorContainer,
          onErrorContainer: _palette.onErrorContainer,
          surface: _palette.darkSurface,
          onSurface: _palette.darkOnSurface,
          onSurfaceVariant: _palette.darkOnSurfaceVariant,
          surfaceTint: _palette.darkPrimary,
          surfaceBright: _palette.darkSurfaceBright,
          surfaceDim: _palette.darkSurfaceDim,
          surfaceContainerLowest: _palette.darkSurfaceContainerLowest,
          surfaceContainerLow: _palette.darkSurfaceContainerLow,
          surfaceContainer: _palette.darkSurfaceContainer,
          surfaceContainerHigh: _palette.darkSurfaceContainerHigh,
          surfaceContainerHighest: _palette.darkSurfaceContainerHighest,
          outline: _palette.darkOutline,
          outlineVariant: _palette.darkOutlineVariant,
          inverseSurface: _palette.surface,
          onInverseSurface: _palette.onSurface,
          inversePrimary: _palette.lightPrimary,
        );

    return _buildTheme(colorScheme, AppThemeTokens.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, AppThemeTokens tokens) {
    final textTheme = _buildTextTheme(colorScheme);
    final fieldRadius = BorderRadius.circular(tokens.formFieldRadius);
    final controlShape = RoundedRectangleBorder(
      borderRadius: fieldRadius,
    );
    final ghostBorderSide = BorderSide(
      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: Size(48, tokens.actionButtonMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(48, tokens.actionButtonMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, tokens.actionButtonMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: controlShape,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          return colorScheme.surfaceContainerLowest;
        }),
        checkColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return colorScheme.onPrimary;
        }),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.formFieldPaddingHorizontal,
          vertical: tokens.formFieldPaddingVerticalComfortable,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: ghostBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: ghostBorderSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelMedium ?? const TextStyle();
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            );
          }
          return base.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          const size = 24.0;
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: size);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: size);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final baseTextTheme =
        ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
        ).textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return interTextTheme.copyWith(
      displayLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.displayLarge,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.displayMedium,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.manrope(
        textStyle: interTextTheme.displaySmall,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.manrope(
        textStyle: interTextTheme.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.manrope(
        textStyle: interTextTheme.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.manrope(
        textStyle: interTextTheme.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.manrope(
        textStyle: interTextTheme.titleSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(textStyle: interTextTheme.bodyLarge),
      bodyMedium: GoogleFonts.inter(textStyle: interTextTheme.bodyMedium),
      bodySmall: GoogleFonts.inter(textStyle: interTextTheme.bodySmall),
      labelLarge: GoogleFonts.inter(
        textStyle: interTextTheme.labelLarge,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: interTextTheme.labelMedium,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: interTextTheme.labelSmall,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

final class _HiveGridPalette {
  _HiveGridPalette();

  /// Stitch **Hive Grid** (`assets/c7a6171e17c644be86621d551b675f2c`).
  /// Project theme roundness: `ROUND_FOUR` → 4px on inputs/buttons (MCP).
  /// Seed `#FFB300`, secondary `#DC813B`, tertiary `#2DB6D1`, neutral `#263238`
  /// (Fidelity / M3 roles).

  final Color lightPrimary = const Color(0xFF7E5700);
  final Color lightPrimaryContainer = const Color(0xFFFFB300);

  /// Stitch accent; `onSecondary` is dark for >= AA contrast on filled labels.
  final Color lightSecondary = const Color(0xFFDC813B);
  final Color lightSecondaryContainer = const Color(0xFFFFE4D6);
  final Color lightTertiary = const Color(0xFF00677E);
  final Color lightTertiaryContainer = const Color(0xFF2DB6D1);

  final Color darkPrimary = const Color(0xFFFFBA38);
  final Color darkOnPrimary = const Color(0xFF402D00);
  final Color darkPrimaryContainer = const Color(0xFF7E5700);
  final Color darkOnPrimaryContainer = const Color(0xFFFFDEAC);

  final Color darkSecondary = const Color(0xFFFFB691);
  final Color darkOnSecondary = const Color(0xFF562100);
  final Color darkSecondaryContainer = const Color(0xFF6B381F);
  final Color darkOnSecondaryContainer = const Color(0xFFFFDBCB);

  final Color darkTertiary = const Color(0xFF43D6FF);
  final Color darkOnTertiary = const Color(0xFF003544);
  final Color darkTertiaryContainer = const Color(0xFF00677E);
  final Color darkOnTertiaryContainer = const Color(0xFFB5EBFF);

  final Color surface = const Color(0xFFF4FAFF);
  final Color surfaceBright = const Color(0xFFF4FAFF);
  final Color surfaceDim = const Color(0xFFCFDCE4);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color surfaceContainerLow = const Color(0xFFE9F6FD);
  final Color surfaceContainer = const Color(0xFFE3F0F8);
  final Color surfaceContainerHigh = const Color(0xFFDDEAF2);

  /// Stitch `surface_variant` / M3 `surfaceContainerHighest`.
  final Color surfaceContainerHighest = const Color(0xFFD7E4EC);

  final Color darkSurface = const Color(0xFF263238);
  final Color darkSurfaceBright = const Color(0xFF2E3B41);
  final Color darkSurfaceDim = const Color(0xFF1B2327);
  final Color darkSurfaceContainerLowest = const Color(0xFF131B1F);
  final Color darkSurfaceContainerLow = const Color(0xFF1F282E);
  final Color darkSurfaceContainer = const Color(0xFF252F35);
  final Color darkSurfaceContainerHigh = const Color(0xFF2B363D);
  final Color darkSurfaceContainerHighest = const Color(0xFF313D45);

  final Color onPrimary = const Color(0xFFFFFFFF);
  final Color onPrimaryContainer = const Color(0xFF6B4900);
  final Color onSecondary = const Color(0xFF1C0F08);
  final Color onSecondaryContainer = const Color(0xFF562100);
  final Color onTertiary = const Color(0xFFFFFFFF);
  final Color onTertiaryContainer = const Color(0xFF00566A);
  final Color onSurface = const Color(0xFF111D23);
  final Color onSurfaceVariant = const Color(0xFF514532);

  final Color darkOnSurface = const Color(0xFFE6F3FB);
  final Color darkOnSurfaceVariant = const Color(0xFFB0BEC5);

  final Color inverseSurface = const Color(0xFF263238);
  final Color inverseOnSurface = const Color(0xFFE6F3FB);
  final Color inversePrimary = const Color(0xFFFFBA38);

  final Color error = const Color(0xFFBA1A1A);
  final Color onError = const Color(0xFFFFFFFF);
  final Color errorContainer = const Color(0xFFFFDAD6);
  final Color onErrorContainer = const Color(0xFF93000A);

  final Color outline = const Color(0xFF847560);
  final Color outlineVariant = const Color(0xFFD6C4AC);
  final Color darkOutline = const Color(0xFF9DACB3);
  final Color darkOutlineVariant = const Color(0xFF5F6B73);
}
