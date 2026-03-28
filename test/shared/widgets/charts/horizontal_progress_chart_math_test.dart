import 'package:colmeia/shared/widgets/charts/horizontal_progress_chart_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizedHorizontalProgress', () {
    test('should clamp to 0..1 when maxValue is positive', () {
      expect(
        normalizedHorizontalProgress(rawValue: 50, maxValue: 100),
        0.5,
      );
      expect(
        normalizedHorizontalProgress(rawValue: 200, maxValue: 100),
        1.0,
      );
      expect(
        normalizedHorizontalProgress(rawValue: -10, maxValue: 100),
        0.0,
      );
    });

    test('should return 0 when maxValue is zero or negative', () {
      expect(
        normalizedHorizontalProgress(rawValue: 10, maxValue: 0),
        0.0,
      );
      expect(
        normalizedHorizontalProgress(rawValue: 10, maxValue: -5),
        0.0,
      );
    });

    test('should treat non-finite numbers as zero', () {
      expect(
        normalizedHorizontalProgress(rawValue: double.nan, maxValue: 100),
        0.0,
      );
      expect(
        normalizedHorizontalProgress(rawValue: 10, maxValue: double.infinity),
        0.0,
      );
      expect(
        normalizedHorizontalProgress(rawValue: double.infinity, maxValue: 100),
        0.0,
      );
    });
  });

  group('defaultHorizontalProgressValueLabel', () {
    test('should format percent style when rowMaxValue is 100', () {
      expect(
        defaultHorizontalProgressValueLabel(
          displayValue: 42,
          rowMaxValue: 100,
        ),
        '42%',
      );
      expect(
        defaultHorizontalProgressValueLabel(
          displayValue: 9.2,
          rowMaxValue: 100,
        ),
        '9.2%',
      );
    });

    test('should format number style when rowMaxValue is not 100', () {
      expect(
        defaultHorizontalProgressValueLabel(
          displayValue: 12,
          rowMaxValue: 500,
        ),
        '12',
      );
      expect(
        defaultHorizontalProgressValueLabel(
          displayValue: 3.5,
          rowMaxValue: 10,
        ),
        '3.5',
      );
    });

    test('should support explicit percent and number modes', () {
      expect(
        defaultHorizontalProgressValueLabel(
          displayValue: 42,
          rowMaxValue: 500,
          mode: AppHorizontalProgressValueLabelMode.percent,
        ),
        '42%',
      );
      expect(
        defaultHorizontalProgressValueLabel(
          displayValue: 42,
          rowMaxValue: 100,
          mode: AppHorizontalProgressValueLabelMode.number,
        ),
        '42',
      );
    });

    test('should treat non-finite values as zero labels', () {
      expect(
        defaultHorizontalProgressValueLabel(
          displayValue: double.nan,
          rowMaxValue: 100,
        ),
        '0.0%',
      );
      expect(
        defaultHorizontalProgressValueLabel(
          displayValue: 10,
          rowMaxValue: double.nan,
          mode: AppHorizontalProgressValueLabelMode.number,
        ),
        '10',
      );
    });
  });
}
