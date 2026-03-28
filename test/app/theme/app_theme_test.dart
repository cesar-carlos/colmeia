import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'light theme registers AppThemeTokens and divider is visible',
    (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final tokens = Theme.of(captured).extension<AppThemeTokens>();
      final colors = Theme.of(captured).extension<AppColors>();
      expect(colors, isNotNull);
      expect(colors!.primaryContainer, const Color(0xFFFFB300));
      expect(colors.background, const Color(0xFFF4FAFF));
      expect(tokens, isNotNull);
      expect(tokens!.gapSm, 8);
      expect(tokens.gapXs, 4);

      final dividerTheme = Theme.of(captured).dividerTheme;
      expect(dividerTheme.thickness, 1);
      expect(dividerTheme.color, isNotNull);
      expect(dividerTheme.color!.a, greaterThan(0));

      final dialogTheme = Theme.of(captured).dialogTheme;
      expect(dialogTheme.elevation, 0);

      final bottomSheetTheme = Theme.of(captured).bottomSheetTheme;
      expect(bottomSheetTheme.elevation, 0);

      final navigationBarTheme = Theme.of(captured).navigationBarTheme;
      expect(navigationBarTheme.elevation, 0);
      expect(navigationBarTheme.shadowColor, Colors.transparent);
      expect(navigationBarTheme.surfaceTintColor, Colors.transparent);
      expect(navigationBarTheme.backgroundColor, isNotNull);
      expect(navigationBarTheme.indicatorColor, isNotNull);
      expect(navigationBarTheme.labelTextStyle, isNotNull);
      final selectedLabel = navigationBarTheme.labelTextStyle!.resolve(
        <WidgetState>{WidgetState.selected},
      );
      final unselectedLabel = navigationBarTheme.labelTextStyle!.resolve(
        <WidgetState>{},
      );
      expect(selectedLabel?.fontWeight, FontWeight.w700);
      expect(unselectedLabel?.fontWeight, FontWeight.w600);
      expect(selectedLabel?.color, isNot(unselectedLabel?.color));
      expect(navigationBarTheme.iconTheme, isNotNull);
      final selectedIcon = navigationBarTheme.iconTheme!.resolve(
        <WidgetState>{WidgetState.selected},
      );
      final unselectedIcon = navigationBarTheme.iconTheme!.resolve(
        <WidgetState>{},
      );
      expect(selectedIcon?.color, isNot(unselectedIcon?.color));
      expect(selectedIcon?.size, 24);
    },
  );

  test('dark theme includes same token keys as light', () {
    final light = AppTheme.light().extension<AppThemeTokens>()!;
    final dark = AppTheme.dark().extension<AppThemeTokens>()!;
    expect(light.gapMd, dark.gapMd);
    expect(light.authLoginGapBrandToForm, dark.authLoginGapBrandToForm);
  });

  test('app colors expose Hive Grid palette for both themes', () {
    final light = AppTheme.light().extension<AppColors>()!;
    final dark = AppTheme.dark().extension<AppColors>()!;

    expect(light.primary, const Color(0xFF7E5700));
    expect(light.secondary, const Color(0xFF9E4200));
    expect(light.tertiary, const Color(0xFF00677E));
    expect(dark.surface, const Color(0xFF263238));
    expect(dark.surfaceContainerHighest, const Color(0xFF313D45));
    expect(dark.primaryFixed, light.primaryFixed);
  });

  test('theme tokens derive color aliases from AppColors', () {
    final lightTheme = AppTheme.light();
    final darkTheme = AppTheme.dark();
    final lightColors = lightTheme.extension<AppColors>()!;
    final darkColors = darkTheme.extension<AppColors>()!;
    final lightTokens = lightTheme.extension<AppThemeTokens>()!;
    final darkTokens = darkTheme.extension<AppThemeTokens>()!;

    expect(lightTokens.success, lightColors.tertiary);
    expect(lightTokens.warning, lightColors.secondary);
    expect(lightTokens.chartSeriesPrimary, lightColors.primary);
    expect(lightTokens.chartSeriesSecondary, lightColors.secondary);
    expect(lightTokens.chartSeriesTertiary, lightColors.tertiary);
    expect(darkTokens.success, darkColors.tertiary);
    expect(darkTokens.warning, darkColors.secondary);
  });
}
