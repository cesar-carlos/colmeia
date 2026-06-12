import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_grouped_column_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tokens = AppThemeTokens.light;

  group('AppGroupedColumnChart.loadingBlockHeight', () {
    test('returns explicit style height when provided', () {
      expect(
        AppGroupedColumnChart.loadingBlockHeight(tokens, styleHeight: 280),
        280,
      );
    });

    test('maps presets to chart height tokens', () {
      expect(
        AppGroupedColumnChart.loadingBlockHeight(
          tokens,
          preset: AppChartPreset.compact,
        ),
        tokens.chartCompactHeight,
      );
      expect(
        AppGroupedColumnChart.loadingBlockHeight(tokens),
        tokens.chartStandardHeight,
      );
    });
  });

  group('AppGroupedColumnChart.resolveNeedsHorizontalScroll', () {
    test('is false when categories fit the viewport', () {
      expect(
        AppGroupedColumnChart.resolveNeedsHorizontalScroll(
          availableWidth: 1200,
          categoryCount: 2,
          categorySlotWidth: 88,
        ),
        isFalse,
      );
    });

    test('is true when content width exceeds the viewport', () {
      expect(
        AppGroupedColumnChart.resolveNeedsHorizontalScroll(
          availableWidth: 200,
          categoryCount: 7,
          categorySlotWidth: 88,
        ),
        isTrue,
      );
    });
  });
}
