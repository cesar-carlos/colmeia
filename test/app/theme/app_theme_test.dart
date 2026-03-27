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
    },
  );

  test('dark theme includes same token keys as light', () {
    final light = AppTheme.light().extension<AppThemeTokens>()!;
    final dark = AppTheme.dark().extension<AppThemeTokens>()!;
    expect(light.gapMd, dark.gapMd);
    expect(light.authLoginGapBrandToForm, dark.authLoginGapBrandToForm);
  });
}
