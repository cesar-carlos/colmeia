import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_chart_point_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapComparisonBarChartPoints', () {
    test('maps labels and applies plot floor metadata', () {
      final mapped = mapComparisonBarChartPoints<_Row>(
        items: const <_Row>[
          _Row(label: 'A', value: 50000),
          _Row(label: 'B', value: 40),
        ],
        values: const <num>[50000, 40],
        labelBuilder: (row) => row.label,
        style: const AppComparisonBarChartStyle(),
      );

      expect(mapped.points, hasLength(2));
      expect(mapped.points.first.label, 'A');
      expect(mapped.hasPlotFloor, isTrue);
      expect(mapped.points.last.plottedValue, isNotNull);
    });

    test('detects extreme spread in mapped metadata', () {
      final mapped = mapComparisonBarChartPoints<_Row>(
        items: const <_Row>[
          _Row(label: 'A', value: 1),
          _Row(label: 'B', value: 20000),
        ],
        values: const <num>[1, 20000],
        labelBuilder: (row) => row.label,
        style: const AppComparisonBarChartStyle(),
      );

      expect(mapped.hasExtremeSpread, isTrue);
    });

    test('wraps x-axis labels when configured', () {
      final mapped = mapComparisonBarChartPoints<_Row>(
        items: const <_Row>[_Row(label: 'Very long category label', value: 10)],
        values: const <num>[10],
        labelBuilder: (row) => row.label,
        style: const AppComparisonBarChartStyle(
          wrapXAxisLabelsInTwoLines: true,
          wrapXAxisCharsPerLine: 8,
        ),
      );

      expect(mapped.points.single.label, contains('\n'));
    });

    test('collects tooltip labels when builder is provided', () {
      final mapped = mapComparisonBarChartPoints<_Row>(
        items: const <_Row>[_Row(label: 'A', value: 12)],
        values: const <num>[12],
        labelBuilder: (row) => row.label,
        tooltipLabelBuilder: (row, value) => '${row.label}: $value',
        style: const AppComparisonBarChartStyle(),
      );

      expect(mapped.tooltipLabels, <String?>['A: 12']);
    });
  });
}

class _Row {
  const _Row({required this.label, required this.value});

  final String label;
  final num value;
}
