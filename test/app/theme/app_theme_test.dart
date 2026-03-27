import 'package:colmeia/app/theme/app_theme.dart';
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
}
