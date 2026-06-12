import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tokens = AppThemeTokens.light;

  group('AppComparisonBarChart.loadingBlockHeight', () {
    test('returns explicit style height when provided', () {
      expect(
        AppComparisonBarChart.loadingBlockHeight(tokens, styleHeight: 280),
        280,
      );
    });

    test('maps presets to chart height tokens', () {
      expect(
        AppComparisonBarChart.loadingBlockHeight(
          tokens,
          preset: AppChartPreset.compact,
        ),
        tokens.chartCompactHeight,
      );
      expect(
        AppComparisonBarChart.loadingBlockHeight(
          tokens,
        ),
        tokens.chartStandardHeight,
      );
    });
  });

  group('AppComparisonBarChartStyle variants', () {
    test('forLandscapeFullscreen disables horizontal scroll chrome', () {
      const base = AppComparisonBarChartStyle(
        height: 220,
        categoryAutoScrollingDelta: 5,
      );

      final landscape = base.forLandscapeFullscreen(height: 300);

      expect(landscape.height, 300);
      expect(landscape.enableAutoScroll, isFalse);
      expect(landscape.showScrollFade, isFalse);
      expect(landscape.stickyPrimaryYAxisWhileScrolling, isFalse);
      expect(landscape.categoryAutoScrollingDelta, isNull);
    });

    test('forPdfExport disables animation and scroll', () {
      const base = AppComparisonBarChartStyle();

      final pdf = base.forPdfExport();

      expect(pdf.animationDuration, Duration.zero);
      expect(pdf.enableAutoScroll, isFalse);
      expect(pdf.showScrollFade, isFalse);
    });
  });
}
