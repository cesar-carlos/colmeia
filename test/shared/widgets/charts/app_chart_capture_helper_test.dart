import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/app_chart_capture_helper.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_result.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:colmeia/shared/widgets/reports/export/report_export_sharing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

ShareExportBytesResult _shareSuccess() {
  return const ShareExportBytesResult(
    shareResult: ShareResult('test', ShareResultStatus.success),
  );
}

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

    await tester.runAsync(() async {
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
          title,
        }) async {
          return _shareSuccess();
        },
      );
    });

    expect(result, isA<ChartShareSuccess>());
  });

  testWidgets('holds guard until share sheet completes', (tester) async {
    final key = GlobalKey();
    var guardHeldDuringShare = false;

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
          title,
        }) async {
          guardHeldDuringShare = ChartShareGuard.isInProgress(key);
          return _shareSuccess();
        },
      );
    });

    expect(result, isA<ChartShareSuccess>());
    expect(guardHeldDuringShare, isTrue);
    expect(ChartShareGuard.isInProgress(key), isFalse);
  });

  testWidgets('skips dedicated export when includeChartImage is false', (
    tester,
  ) async {
    final key = GlobalKey();
    var exportBuilderInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(key: key, width: 10, height: 10),
        ),
      ),
    );
    await tester.pump();

    final hostContext = tester.element(find.byType(Scaffold));
    late ChartShareResult result;
    await tester.runAsync(() async {
      result = await captureAndShareChart(
        key,
        title: 'Table with builder',
        tableData: const ChartShareTableData(
          headers: <String>['Product', 'Sales'],
          rows: <List<String>>[
            <String>['Coffee', '10'],
          ],
        ),
        chartExportBuilder: (_) {
          exportBuilderInvoked = true;
          return const SizedBox(width: 100, height: 100);
        },
        includeChartImage: false,
        exportCaptureContext: hostContext,
        shareBytes: ({
          required bytes,
          required fileName,
          required mimeType,
          subject,
          title,
        }) async {
          return _shareSuccess();
        },
      );
    });

    expect(result, isA<ChartShareSuccess>());
    expect(exportBuilderInvoked, isFalse);
  });

  testWidgets('table-only share succeeds when dedicated export capture fails', (
    tester,
  ) async {
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(key: key, width: 10, height: 10),
        ),
      ),
    );
    await tester.pump();

    final hostContext = tester.element(find.byType(Scaffold));
    late ChartShareResult result;
    await tester.runAsync(() async {
      result = await captureAndShareChart(
        key,
        title: 'Branch ranking',
        tableData: const ChartShareTableData(
          headers: <String>['Product', 'Sales'],
          rows: <List<String>>[
            <String>['Coffee', '10'],
          ],
        ),
        chartExportBuilder: (_) => const SizedBox.shrink(),
        exportCaptureContext: hostContext,
        shareBytes: ({
          required bytes,
          required fileName,
          required mimeType,
          subject,
          title,
        }) async {
          return _shareSuccess();
        },
      );
    });

    expect(result, isA<ChartShareSuccess>());
  });

  testWidgets(
    'falls back to boundary when dedicated export has no overlay context',
    (tester) async {
      final key = GlobalKey();
      late ChartShareResult result;

      await tester.pumpWidget(_chartBoundary(key: key));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        result = await captureAndShareChart(
          key,
          title: 'Boundary fallback',
          chartExportBuilder: (_) => const SizedBox.shrink(),
          shareBytes: ({
            required bytes,
            required fileName,
            required mimeType,
            subject,
            title,
          }) async {
            return _shareSuccess();
          },
        );
      });

      expect(result, isA<ChartShareSuccess>());
    },
  );

  testWidgets('returns sharePlatformFailed with temp path when share unavailable', (
    tester,
  ) async {
    final key = GlobalKey();
    late ChartShareResult result;

    await tester.pumpWidget(_chartBoundary(key: key));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      result = await captureAndShareChart(
        key,
        title: 'Chart',
        shareBytes: ({
          required bytes,
          required fileName,
          required mimeType,
          subject,
          title,
        }) async {
          return const ShareExportBytesResult(
            shareResult: ShareResult('test', ShareResultStatus.unavailable),
            tempFilePath: r'C:\temp\chart.pdf',
          );
        },
      );
    });

    expect(result, isA<ChartShareFailure>());
    final failure = result as ChartShareFailure;
    expect(failure.reason, ChartShareFailureReason.sharePlatformFailed);
    expect(failure.pdfFilePath, r'C:\temp\chart.pdf');
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
