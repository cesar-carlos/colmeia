import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_chart_margin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  group('comparisonBarDataLabelLineCount', () {
    test('counts newline-separated lines', () {
      expect(comparisonBarDataLabelLineCount(r'R$ 65,4 mil'), 1);
      expect(
        comparisonBarDataLabelLineCount(
          'R\$ 65,4 mil\nTicket médio: R\$ 82,71',
        ),
        2,
      );
      expect(comparisonBarDataLabelLineCount(null), 0);
      expect(comparisonBarDataLabelLineCount(''), 0);
    });
  });

  testWidgets(
    'resolveComparisonBarChartMargin reserves extra top for multi-line labels',
    (tester) async {
      late EdgeInsets singleLine;
      late EdgeInsets twoLines;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              singleLine = resolveComparisonBarChartMargin(
                context,
                showDataLabels: true,
                dataLabelAlignment: ChartDataLabelAlignment.outer,
                dataLabelOffset: const Offset(0, 8),
                chartPadding: null,
              );
              twoLines = resolveComparisonBarChartMargin(
                context,
                showDataLabels: true,
                dataLabelAlignment: ChartDataLabelAlignment.outer,
                dataLabelOffset: const Offset(0, 8),
                chartPadding: null,
                maxDataLabelLines: 2,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(twoLines.top, greaterThan(singleLine.top));
    },
  );

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
    expect(margin.left, greaterThan(0));
    expect(margin.right, greaterThan(0));
  });

  testWidgets(
    'resolveComparisonBarChartMargin adds annotation widget inset when labels are annotations',
    (tester) async {
      late EdgeInsets fullMargin;
      late EdgeInsets annotationMargin;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              fullMargin = resolveComparisonBarChartMargin(
                context,
                showDataLabels: true,
                dataLabelAlignment: ChartDataLabelAlignment.outer,
                dataLabelOffset: const Offset(0, 8),
                chartPadding: null,
              );
              annotationMargin = resolveComparisonBarChartMargin(
                context,
                showDataLabels: true,
                dataLabelAlignment: ChartDataLabelAlignment.outer,
                dataLabelOffset: const Offset(0, 8),
                chartPadding: null,
                valueLabelsRenderedAsChartAnnotations: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(
        annotationMargin.top,
        equals(fullMargin.top + kComparisonBarAnnotationLabelVerticalInset),
      );
    },
  );

  testWidgets(
    'resolveComparisonBarChartMargin adds pill allowance for pill-shaped annotation labels',
    (tester) async {
      late EdgeInsets annotationOnly;
      late EdgeInsets annotationPill;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              annotationOnly = resolveComparisonBarChartMargin(
                context,
                showDataLabels: true,
                dataLabelAlignment: ChartDataLabelAlignment.outer,
                dataLabelOffset: const Offset(0, 8),
                chartPadding: null,
                valueLabelsRenderedAsChartAnnotations: true,
              );
              annotationPill = resolveComparisonBarChartMargin(
                context,
                showDataLabels: true,
                dataLabelAlignment: ChartDataLabelAlignment.outer,
                dataLabelOffset: const Offset(0, 8),
                chartPadding: null,
                valueLabelsRenderedAsChartAnnotations: true,
                dataLabelAnnotationUsesPillBackground: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(
        annotationPill.top,
        equals(
          annotationOnly.top + kComparisonBarAnnotationPillExtraTopAllowance,
        ),
      );
    },
  );

  testWidgets(
    'resolveComparisonBarChartMargin adds outerDataLabelTopReserve after headroom',
    (tester) async {
      late EdgeInsets withoutReserve;
      late EdgeInsets withReserve;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              withoutReserve = resolveComparisonBarChartMargin(
                context,
                showDataLabels: true,
                dataLabelAlignment: ChartDataLabelAlignment.outer,
                dataLabelOffset: const Offset(0, 8),
                chartPadding: null,
              );
              withReserve = resolveComparisonBarChartMargin(
                context,
                showDataLabels: true,
                dataLabelAlignment: ChartDataLabelAlignment.outer,
                dataLabelOffset: const Offset(0, 8),
                chartPadding: null,
                outerDataLabelTopReserve: 12,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(withReserve.top, equals(withoutReserve.top + 12));
    },
  );

  testWidgets(
    'resolveComparisonBarChartMargin can skip outer label top margin',
    (tester) async {
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
                chartPadding: const EdgeInsets.only(top: 4, bottom: 8),
                reserveOuterDataLabelTopMargin: false,
                valueLabelsRenderedAsChartAnnotations: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(margin.top, 4);
      expect(margin.bottom, 8);
      expect(margin.left, greaterThan(0));
      expect(margin.right, greaterThan(0));
    },
  );

  testWidgets(
    'resolveComparisonBarChartMargin returns base when no outer labels',
    (
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
    },
  );
}
