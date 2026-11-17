import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/app_skeleton_effect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark skeleton stays within the dark surface palette', () {
    final colors = AppTheme.dark().colorScheme;
    final effect = appSkeletonEffect(colors);

    expect(effect.colors, <Object>[
      colors.surfaceContainerHighest,
      colors.surfaceContainerHigh,
      colors.surfaceContainerHighest,
    ]);
    for (final color in effect.colors) {
      expect(color.computeLuminance(), lessThan(0.1));
      expect(
        color.computeLuminance(),
        greaterThan(colors.surfaceContainerLowest.computeLuminance()),
      );
    }
  });

  test('light and dark skeletons follow their respective themes', () {
    final light = appSkeletonEffect(AppTheme.light().colorScheme);
    final dark = appSkeletonEffect(AppTheme.dark().colorScheme);

    expect(light.colors, isNot(dark.colors));
    for (final color in light.colors) {
      expect(color.computeLuminance(), greaterThan(0.5));
    }
  });
}
