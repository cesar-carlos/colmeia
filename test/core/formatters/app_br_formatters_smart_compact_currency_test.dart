import 'package:checks/checks.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBrFormatters.smartCompactCurrency', () {
    test(r'uses full currency below R$ 1000 to avoid "mil" ambiguity', () {
      check(AppBrFormatters.smartCompactCurrency(0)).contains('0,00');
      check(AppBrFormatters.smartCompactCurrency(26.8))
          .equals(AppBrFormatters.currency(26.8));
      check(AppBrFormatters.smartCompactCurrency(999.99))
          .equals(AppBrFormatters.currency(999.99));
    });

    test(r'switches to compact above R$ 1000', () {
      final compact1k = AppBrFormatters.smartCompactCurrency(1000);
      check(compact1k).equals(AppBrFormatters.compactCurrency(1000));
      check(compact1k).contains('mil');

      final compact20k = AppBrFormatters.smartCompactCurrency(20719);
      check(compact20k).contains('mil');
    });

    test('handles negative values by absolute threshold', () {
      check(AppBrFormatters.smartCompactCurrency(-500))
          .equals(AppBrFormatters.currency(-500));
      check(AppBrFormatters.smartCompactCurrency(-2500))
          .equals(AppBrFormatters.compactCurrency(-2500));
    });
  });
}
