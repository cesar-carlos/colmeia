import 'package:colmeia/shared/widgets/charts/app_chart_capture_helper.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cartesianChartExportWidth scales with item count', () {
    expect(
      cartesianChartExportWidth(itemCount: 12, minSlotWidth: 48),
      576,
    );
    expect(
      cartesianChartExportWidth(itemCount: 0, minSlotWidth: 48),
      48,
    );
  });

  test('cartesianChartExportWidth caps at max logical width', () {
    expect(
      cartesianChartExportWidth(itemCount: 1000, minSlotWidth: 48),
      kCartesianChartExportMaxLogicalWidth,
    );
  });

  testWidgets('captureChartFromExportBuilder captures offscreen widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {},
                child: const Text('Host'),
              ),
            );
          },
        ),
      ),
    );

    final hostContext = tester.element(find.text('Host'));
    final captureFuture = captureChartFromExportBuilder(
      overlay: Overlay.of(hostContext),
      devicePixelRatio: View.of(hostContext).devicePixelRatio,
      chartExportBuilder: (exportContext) {
        return wrapCartesianChartForPdfExport(
          context: exportContext,
          itemCount: 3,
          minSlotWidth: 80,
          height: 120,
          chart: const ColoredBox(
            color: Color(0xFF336699),
            child: SizedBox.expand(),
          ),
        );
      },
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    late ChartPngCapture? capture;
    await tester.runAsync(() async {
      capture = await captureFuture;
    });

    expect(capture, isNotNull);
    expect(capture!.bytes, isNotEmpty);
  });
}
