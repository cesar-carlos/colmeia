import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/app_chart_capture_helper.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

Widget _chartBoundary({required GlobalKey key}) {
  return MaterialApp(
    home: Scaffold(
      body: RepaintBoundary(
        key: key,
        child: const ColoredBox(
          color: Color(0xFF112233),
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('captures PNG from repaint boundary', (tester) async {
    final key = GlobalKey();

    await tester.pumpWidget(_chartBoundary(key: key));
    await tester.pumpAndSettle();

    late Uint8List? pngBytes;
    await tester.runAsync(() async {
      pngBytes = await captureChartPngBytes(key);
    });

    expect(pngBytes, isNotNull);
    expect(pngBytes, isNotEmpty);
  });

  testWidgets('captures PNG immediately after first frame without extra pump', (
    tester,
  ) async {
    final key = GlobalKey();

    await tester.pumpWidget(_chartBoundary(key: key));

    late Uint8List? pngBytes;
    await tester.runAsync(() async {
      pngBytes = await captureChartPngBytes(key);
    });

    expect(pngBytes, isNotNull);
    expect(pngBytes, isNotEmpty);
  });

  testWidgets('waitForBoundaryReady returns true for painted boundary', (
    tester,
  ) async {
    final key = GlobalKey();

    await tester.pumpWidget(_chartBoundary(key: key));
    await tester.pump();

    final boundary = key.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;

    late bool ready;
    await tester.runAsync(() async {
      ready = await waitForBoundaryReady(boundary);
    });

    expect(ready, isTrue);
  });

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

  testWidgets('returns shareInProgress when guard is already held', (
    tester,
  ) async {
    final key = GlobalKey();
    ChartShareGuard.tryAcquire(key);
    addTearDown(() => ChartShareGuard.release(key));

    await tester.pumpWidget(const SizedBox.shrink());

    final result = await captureAndShareChart(
      key,
      title: 'Chart',
      tableData: const ChartShareTableData(
        headers: <String>['A'],
        rows: <List<String>>[
          <String>['1'],
        ],
      ),
    );

    expect(result, isA<ChartShareFailure>());
    expect(
      (result as ChartShareFailure).reason,
      ChartShareFailureReason.shareInProgress,
    );
  });

  testWidgets('table-only fallback shares PDF without repaint boundary', (
    tester,
  ) async {
    final key = GlobalKey();
    late ChartShareResult result;

    await tester.pumpWidget(const SizedBox.shrink());

    result = await captureAndShareChart(
      key,
      title: 'Table only',
      tableData: const ChartShareTableData(
        headers: <String>['Metric', 'Value'],
        rows: <List<String>>[
          <String>['Sales', '10'],
        ],
      ),
      shareBytes: ({
        required bytes,
        required fileName,
        required mimeType,
        subject,
      }) async {
        return const ShareResult('test', ShareResultStatus.success);
      },
    );

    expect(result, isA<ChartShareSuccess>());
  });

  testWidgets('releases guard before invoking share', (tester) async {
    final key = GlobalKey();
    var guardHeldDuringShare = true;

    await tester.pumpWidget(_chartBoundary(key: key));
    await tester.pumpAndSettle();

    late ChartShareResult result;
    await tester.runAsync(() async {
      result = await captureAndShareChart(
        key,
        title: 'Chart',
        shareBytes: ({
          required bytes,
          required fileName,
          required mimeType,
          subject,
        }) async {
          guardHeldDuringShare = ChartShareGuard.isInProgress(key);
          return const ShareResult('test', ShareResultStatus.success);
        },
      );
    });

    expect(result, isA<ChartShareSuccess>());
    expect(guardHeldDuringShare, isFalse);
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
