import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tokens = AppThemeTokens.light;

  group('AppComboChart.loadingBlockHeight', () {
    test('returns explicit style height when provided', () {
      expect(
        AppComboChart.loadingBlockHeight(tokens, styleHeight: 320),
        320,
      );
    });

    test('maps presets to chart height tokens', () {
      expect(
        AppComboChart.loadingBlockHeight(
          tokens,
          preset: AppChartPreset.compact,
        ),
        tokens.chartCompactHeight,
      );
      expect(
        AppComboChart.loadingBlockHeight(
          tokens,
        ),
        tokens.chartStandardHeight,
      );
      expect(
        AppComboChart.loadingBlockHeight(
          tokens,
          preset: AppChartPreset.explorable,
        ),
        tokens.chartStandardHeight,
      );
    });
  });

  group('AppComboChartStyle variants', () {
    test('forLandscapeFullscreen disables scroll chrome', () {
      const base = AppComboChartStyle(
        height: 240,
        categoryAutoScrollingDelta: 4,
      );

      final landscape = base.forLandscapeFullscreen();

      expect(landscape.height, 240);
      expect(landscape.enableAutoScroll, isFalse);
      expect(landscape.showScrollFade, isFalse);
      expect(landscape.stickyPrimaryYAxisWhileScrolling, isFalse);
      expect(landscape.compactLayout, isTrue);
      expect(landscape.categoryAutoScrollingDelta, isNull);
    });

    test('forPdfExport disables animation and scroll', () {
      const base = AppComboChartStyle();

      final pdf = base.forPdfExport();

      expect(pdf.animationDuration, Duration.zero);
      expect(pdf.enableAutoScroll, isFalse);
      expect(pdf.showScrollFade, isFalse);
      expect(pdf.stickyPrimaryYAxisWhileScrolling, isFalse);
    });
  });
}
