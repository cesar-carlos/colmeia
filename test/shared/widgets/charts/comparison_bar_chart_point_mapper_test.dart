import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_chart_point_mapper.dart';
import 'package:flutter/material.dart';
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

    test('truncates tooltip labels when max chars is set', () {
      final mapped = mapComparisonBarChartPoints<_Row>(
        items: const <_Row>[_Row(label: 'A', value: 1)],
        values: const <num>[1],
        labelBuilder: (row) => row.label,
        tooltipLabelBuilder: (_, _) => 'abcdefghijklmnop',
        style: const AppComparisonBarChartStyle(tooltipLabelMaxChars: 6),
      );

      expect(mapped.tooltipLabels?.single, 'abcdef\u2026');
    });

    test('collapses x-axis labels when max chars is set', () {
      final mapped = mapComparisonBarChartPoints<_Row>(
        items: const <_Row>[
          _Row(label: 'Very long seller name here', value: 10),
        ],
        values: const <num>[10],
        labelBuilder: (row) => row.label,
        style: const AppComparisonBarChartStyle(xLabelMaxChars: 8),
      );

      expect(mapped.points.single.label, endsWith('\u2026'));
    });

    test('skips plot floor when strict linear heights are enabled', () {
      final mapped = mapComparisonBarChartPoints<_Row>(
        items: const <_Row>[
          _Row(label: 'A', value: 50000),
          _Row(label: 'B', value: 40),
        ],
        values: const <num>[50000, 40],
        labelBuilder: (row) => row.label,
        style: const AppComparisonBarChartStyle(strictLinearBarHeights: true),
      );

      expect(mapped.hasPlotFloor, isFalse);
      expect(
        mapped.points.every((point) => point.plottedValue == null),
        isTrue,
      );
    });

    test('collects per-item colors and data labels when configured', () {
      final mapped = mapComparisonBarChartPoints<_Row>(
        items: const <_Row>[
          _Row(label: 'A', value: 10),
          _Row(label: 'B', value: 20),
        ],
        values: const <num>[10, 20],
        labelBuilder: (row) => row.label,
        colorBuilder: (row) =>
            row.label == 'A' ? const Color(0xFFFF0000) : null,
        dataLabelBuilder: (row, value) => '${row.label}:$value',
        style: const AppComparisonBarChartStyle(showDataLabels: true),
      );

      expect(mapped.pointColors, <Color?>[const Color(0xFFFF0000), null]);
      expect(mapped.dataLabels, <String?>['A:10', 'B:20']);
    });
  });

  group('truncateComparisonTooltipLabel', () {
    test('returns null for null input', () {
      expect(truncateComparisonTooltipLabel(null, 10), isNull);
    });

    test('keeps short labels unchanged', () {
      expect(truncateComparisonTooltipLabel('short', 12), 'short');
    });
  });

  group('buildComparisonBarChartSemanticsLabel', () {
    test('joins plot floor and spread notices when flags are true', () {
      expect(
        buildComparisonBarChartSemanticsLabel(
          hasPlotFloor: true,
          hasExtremeSpread: true,
          plotFloorAccessibilityNotice: 'Floor notice.',
          extremeSpreadAccessibilityNotice: 'Spread notice.',
          chartSemanticsCoordinatorNotice: 'Coordinator.',
        ),
        'Floor notice. Spread notice. Coordinator.',
      );
    });

    test('ignores notices when corresponding flag is false', () {
      expect(
        buildComparisonBarChartSemanticsLabel(
          hasPlotFloor: false,
          hasExtremeSpread: true,
          plotFloorAccessibilityNotice: 'Floor notice.',
          extremeSpreadAccessibilityNotice: 'Spread notice.',
        ),
        'Spread notice.',
      );
    });

    test('returns null when nothing applies', () {
      expect(
        buildComparisonBarChartSemanticsLabel(
          hasPlotFloor: false,
          hasExtremeSpread: false,
        ),
        isNull,
      );
    });
  });
}

class _Row {
  const _Row({required this.label, required this.value});

  final String label;
  final num value;
}
