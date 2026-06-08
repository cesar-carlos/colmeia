import 'package:colmeia/shared/widgets/charts/app_chart_capture_helper.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns missingBoundary when key has no context', (
    tester,
  ) async {
    final key = GlobalKey();
    late ChartShareResult result;
    await tester.pumpWidget(const SizedBox.shrink());
    result = await captureAndShareChart(key);
    expect(result, isA<ChartShareFailure>());
    expect(
      (result as ChartShareFailure).reason,
      ChartShareFailureReason.missingBoundary,
    );
  });

  testWidgets('returns missingBoundary when key has no context and no table', (
    tester,
  ) async {
    final key = GlobalKey();
    late ChartShareResult result;
    await tester.pumpWidget(const SizedBox.shrink());
    result = await captureAndShareChart(
      key,
      title: 'Chart',
      tableData: const ChartShareTableData(
        headers: <String>['A'],
        rows: <List<String>>[],
      ),
    );
    expect(result, isA<ChartShareFailure>());
    expect(
      (result as ChartShareFailure).reason,
      ChartShareFailureReason.missingBoundary,
    );
  });

  testWidgets(
    'returns invalidRenderObject when key is not a repaint boundary',
    (
      tester,
    ) async {
      final key = GlobalKey();
      late ChartShareResult result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(key: key, width: 10, height: 10),
          ),
        ),
      );

      result = await captureAndShareChart(key);
      expect(result, isA<ChartShareFailure>());
      expect(
        (result as ChartShareFailure).reason,
        ChartShareFailureReason.invalidRenderObject,
      );
    },
  );
}
