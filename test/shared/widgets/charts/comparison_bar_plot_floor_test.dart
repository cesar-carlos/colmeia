import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_plot_floor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('comboNumericAxisMaximum', () {
    test('uses series max only with modest headroom', () {
      expect(
        comboNumericAxisMaximum(<num>[12000, 35000, 28000]),
        50000,
      );
      expect(comboNumericAxisMaximum(<num>[35000]), 50000);
      expect(comboNumericAxisMaximum(const <num>[]), isNull);
    });
  });

  group('comparisonBarAxisSpreadNiceCeil', () {
    test('rounds up to 1-2-5-10 style steps', () {
      expect(comparisonBarAxisSpreadNiceCeil(32500), 50000);
      expect(comparisonBarAxisSpreadNiceCeil(1000), 1000);
      expect(comparisonBarAxisSpreadNiceCeil(1001), 2000);
    });
  });

  group('comparisonBarDenominatorForPlotFloor', () {
    test('is at least the nice ceiling of padded max', () {
      expect(comparisonBarDenominatorForPlotFloor(25000), greaterThan(25000));
    });
  });

  group('applyComparisonBarPlotHeightFloor', () {
    test('lifts tiny positives when not strict', () {
      final raw = <AppChartPoint>[
        const AppChartPoint(label: 'A', value: 50000),
        const AppChartPoint(label: 'B', value: 40),
      ];
      final out = applyComparisonBarPlotHeightFloor(
        raw,
        0.03,
        strictLinearBarHeights: false,
      );
      expect(out[0].plottedValue, isNull);
      expect(out[1].plottedValue, isNotNull);
      expect(out[1].value, 40);
      expect(out[1].plottedValue, greaterThan(40));
    });

    test('does not lift when strictLinearBarHeights is true', () {
      final raw = <AppChartPoint>[
        const AppChartPoint(label: 'A', value: 50000),
        const AppChartPoint(label: 'B', value: 40),
      ];
      final out = applyComparisonBarPlotHeightFloor(
        raw,
        0.03,
        strictLinearBarHeights: true,
      );
      expect(out[1].plottedValue, isNull);
    });
  });

  group('comparisonBarValuesHaveExtremeSpread', () {
    test('detects large max/min ratio', () {
      expect(
        comparisonBarValuesHaveExtremeSpread(<num>[1, 20000]),
        isTrue,
      );
      expect(
        comparisonBarValuesHaveExtremeSpread(<num>[100, 200]),
        isFalse,
      );
    });
  });
}
