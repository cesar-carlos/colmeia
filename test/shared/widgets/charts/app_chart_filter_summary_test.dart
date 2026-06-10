import 'package:colmeia/shared/widgets/charts/app_chart_filter_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppChartFilterSummary', () {
    test('spacedMiddleDotSeparator uses middle dot', () {
      expect(
        AppChartFilterSummary.spacedMiddleDotSeparator,
        ' ${String.fromCharCode(AppChartFilterSummary.middleDotCodePoint)} ',
      );
    });

    test('splitOnMiddleDot splits on middle dot', () {
      final summary =
          'A: 1${AppChartFilterSummary.spacedMiddleDotSeparator}B: 2';
      expect(
        AppChartFilterSummary.splitOnMiddleDot(summary),
        <String>['A: 1', 'B: 2'],
      );
    });

    test('normalizeMiddleDotMojibake repairs Latin-1 misread UTF-8', () {
      const separator = AppChartFilterSummary.middleDotCodePoint;
      final corrupted = 'A${String.fromCharCodes(<int>[0x00C2, separator])}B';
      expect(
        AppChartFilterSummary.splitOnMiddleDot(corrupted),
        <String>['A', 'B'],
      );
    });
  });
}
