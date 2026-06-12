import 'package:colmeia/shared/widgets/charts/comparison_bar_x_axis_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatComparisonBarXAxisLabelCollapsed', () {
    test('trims whitespace and collapses long labels', () {
      expect(
        formatComparisonBarXAxisLabelCollapsed(
          '  Very   long   category  ',
          maxChars: 10,
        ),
        'Very long \u2026',
      );
    });

    test('enforces minimum of four visible characters before ellipsis', () {
      expect(
        formatComparisonBarXAxisLabelCollapsed('ABCDEFGH', maxChars: 2),
        'ABCD\u2026',
      );
    });

    test('returns empty string for blank input', () {
      expect(
        formatComparisonBarXAxisLabelCollapsed('   ', maxChars: 8),
        '',
      );
    });
  });

  group('formatComparisonBarXAxisLabelWrapped', () {
    test('wraps on word boundaries up to maxLines', () {
      final wrapped = formatComparisonBarXAxisLabelWrapped(
        'Receita por categoria longa',
        maxCharsPerLine: 12,
      );

      expect(wrapped, contains('\n'));
      expect(wrapped.split('\n'), hasLength(2));
    });

    test('preserves explicit newline segments independently', () {
      expect(
        formatComparisonBarXAxisLabelWrapped(
          'Seg 01/06\nTer 02/06\nQua 03/06',
          maxCharsPerLine: 8,
        ),
        'Seg 01/0\u2026\nTer 02/0\u2026',
      );
    });

    test('ellipsis overflow on last line when remainder does not fit', () {
      final wrapped = formatComparisonBarXAxisLabelWrapped(
        'Alpha Beta Gamma Delta',
        maxCharsPerLine: 8,
      );

      expect(wrapped.endsWith('\u2026'), isTrue);
    });
  });

  group('formatComparisonBarXAxisLabelTwoLines', () {
    test('delegates to wrapped formatter with two lines', () {
      expect(
        formatComparisonBarXAxisLabelTwoLines(
          'One two three four five six',
          maxCharsPerLine: 10,
        ),
        formatComparisonBarXAxisLabelWrapped(
          'One two three four five six',
          maxCharsPerLine: 10,
        ),
      );
    });
  });
}
