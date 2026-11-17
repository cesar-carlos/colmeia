import 'package:colmeia/app/theme/app_legacy_material_theme.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    test('legacy widgets inherit colors and typography (dark: $dark)', () {
      final source = dark ? AppTheme.dark() : AppTheme.light();
      final adapted = buildLegacyMaterialTheme(source);
      expect(adapted.brightness, source.brightness);
      expect(adapted.colorScheme.primary, source.colorScheme.primary);
      expect(adapted.colorScheme.onPrimary, source.colorScheme.onPrimary);
      expect(adapted.colorScheme.surface, source.colorScheme.surface);
      expect(adapted.colorScheme.onSurface, source.colorScheme.onSurface);
      expect(
        adapted.colorScheme.surfaceContainerHighest,
        source.colorScheme.surfaceContainerHighest,
      );
      expect(adapted.scaffoldBackgroundColor, source.scaffoldBackgroundColor);
      expect(adapted.textTheme.bodyMedium, source.textTheme.bodyMedium);
      expect(adapted.platform, source.platform);
    });
  }
}
