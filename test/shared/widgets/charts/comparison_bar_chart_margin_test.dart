import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_chart_margin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  testWidgets('resolveComparisonBarChartMargin reserves top for outer labels', (
    tester,
  ) async {
    late EdgeInsets margin;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            margin = resolveComparisonBarChartMargin(
              context,
              showDataLabels: true,
              dataLabelAlignment: ChartDataLabelAlignment.outer,
              dataLabelOffset: const Offset(0, 8),
              chartPadding: null,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(margin.top, greaterThanOrEqualTo(32));
  });

  testWidgets('resolveComparisonBarChartMargin returns base when no outer labels', (
    tester,
  ) async {
    late EdgeInsets margin;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            margin = resolveComparisonBarChartMargin(
              context,
              showDataLabels: true,
              dataLabelAlignment: ChartDataLabelAlignment.top,
              dataLabelOffset: null,
              chartPadding: const EdgeInsets.only(top: 4),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(margin.top, 4);
  });
}
