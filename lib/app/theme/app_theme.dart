import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_font_families.dart';
import 'package:colmeia/shared/design_system/app_motion_tokens.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final Map<_ThemeCacheKey, ThemeData> _cache =
      <_ThemeCacheKey, ThemeData>{};

  static ThemeData light({TargetPlatform? platform}) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return _cache.putIfAbsent(
      _ThemeCacheKey(
        brightness: Brightness.light,
        platform: resolvedPlatform,
      ),
      () => _buildTheme(
        AppColors.light,
        AppThemeTokens.light,
        platform: resolvedPlatform,
      ),
    );
  }

  static ThemeData dark({TargetPlatform? platform}) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return _cache.putIfAbsent(
      _ThemeCacheKey(
        brightness: Brightness.dark,
        platform: resolvedPlatform,
      ),
      () => _buildTheme(
        AppColors.dark,
        AppThemeTokens.dark,
        platform: resolvedPlatform,
      ),
    );
  }

  static ThemeData _buildTheme(
    AppColors colors,
    AppThemeTokens tokens, {
    TargetPlatform? platform,
  }) {
    final colorScheme = colors.toColorScheme();
    final textTheme = _buildTextTheme(colorScheme);
    final typography = AppTypographyTokens.fromTheme(
      textTheme: textTheme,
      colorScheme: colorScheme,
    );
    final fieldRadius = BorderRadius.circular(tokens.formFieldRadius);
    final controlShape = RoundedRectangleBorder(
      borderRadius: fieldRadius,
    );
    final segmentedControlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.formFieldRadius + 4),
    );
    final ghostBorderSide = BorderSide(
      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
    );
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    final persistentDesktopScrollbar = _usesPersistentDesktopScrollbar(
      resolvedPlatform,
    );

    return ThemeData(
      useMaterial3: true,
      platform: resolvedPlatform,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: colors.background,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        tokens,
        typography,
        AppMotionTokens.standard,
      ],
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll<bool>(
          persistentDesktopScrollbar,
        ),
        trackVisibility: WidgetStatePropertyAll<bool>(
          persistentDesktopScrollbar,
        ),
        thickness: WidgetStatePropertyAll<double>(
          persistentDesktopScrollbar ? 12 : 10,
        ),
        radius: Radius.circular(tokens.formFieldRadius),
      ),
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
          foregroundColor: colorScheme.primary,
          minimumSize: Size(48, tokens.actionButtonMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: controlShape,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, tokens.actionButtonMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: controlShape,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.resolveWith((states) {
            return typography.caption.copyWith(
              fontSize: 14,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            );
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant.withValues(alpha: 0.48);
            }
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimaryContainer;
            }
            return colorScheme.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
            }
            if (states.contains(WidgetState.selected)) {
              return Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.12),
                colorScheme.primaryContainer,
              );
            }
            return colorScheme.surfaceContainerLowest;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.32),
              );
            }
            return BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            );
          }),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.04);
            }
            return null;
          }),
          minimumSize: WidgetStateProperty.all(const Size(0, 40)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          shape: WidgetStateProperty.all(segmentedControlShape),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
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
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        minWidth: 72,
        useIndicator: true,
        selectedIconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        alignLabelWithHint: true,
        errorMaxLines: 3,
        helperMaxLines: 3,
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
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.92),
            width: 1.5,
          ),
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
        indicatorColor: colorScheme.primaryContainer,
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
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outlineVariant;
        }),
      ),
    );
  }

  static bool _usesPersistentDesktopScrollbar(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.iOS => false,
    };
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final baseTextTheme =
        ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
        ).textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
          fontFamily: AppFontFamilies.inter,
        );

    return baseTextTheme.copyWith(
      displayLarge: _manropeStyle(
        baseTextTheme.displayLarge,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: _manropeStyle(
        baseTextTheme.displayMedium,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: _manropeStyle(
        baseTextTheme.displaySmall,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: _manropeStyle(
        baseTextTheme.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: _manropeStyle(
        baseTextTheme.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: _manropeStyle(
        baseTextTheme.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: _manropeStyle(
        baseTextTheme.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: _manropeStyle(
        baseTextTheme.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: _manropeStyle(
        baseTextTheme.titleSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: _interStyle(baseTextTheme.bodyLarge),
      bodyMedium: _interStyle(baseTextTheme.bodyMedium),
      bodySmall: _interStyle(baseTextTheme.bodySmall),
      labelLarge: _interStyle(
        baseTextTheme.labelLarge,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: _interStyle(
        baseTextTheme.labelMedium,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: _interStyle(
        baseTextTheme.labelSmall,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static TextStyle _interStyle(
    TextStyle? base, {
    FontWeight? fontWeight,
  }) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppFontFamilies.inter,
      fontWeight: fontWeight,
    );
  }

  static TextStyle _manropeStyle(
    TextStyle? base, {
    required FontWeight fontWeight,
  }) {
    return (base ?? const TextStyle()).copyWith(
      fontFamily: AppFontFamilies.manrope,
      fontWeight: fontWeight,
    );
  }
}

@immutable
class _ThemeCacheKey {
  const _ThemeCacheKey({
    required this.brightness,
    required this.platform,
  });

  final Brightness brightness;
  final TargetPlatform platform;

  @override
  bool operator ==(Object other) {
    return other is _ThemeCacheKey &&
        other.brightness == brightness &&
        other.platform == platform;
  }

  @override
  int get hashCode => Object.hash(brightness, platform);
}
