import 'dart:async';

import 'package:colmeia/features/sales/presentation/utils/sales_auto_refresh_state_mixin.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not reload while auto-refresh is off', (tester) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
    );

    await tester.pump(const Duration(minutes: 30));

    expect(reloadCount, 0);
  });

  testWidgets('reloads after the selected interval elapses', (tester) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await tester.pump(const Duration(minutes: 4, seconds: 59));

    expect(reloadCount, 0);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(reloadCount, 1);
  });

  testWidgets('does not start an overlapping auto-refresh reload', (
    tester,
  ) async {
    var reloadCount = 0;
    final completer = Completer<void>();

    await _pumpHarness(
      tester,
      onReload: () {
        reloadCount += 1;
        return completer.future;
      },
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));

    expect(reloadCount, 1);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    await tester.pump();

    expect(reloadCount, 2);
  });

  testWidgets('turning off auto-refresh cancels the timer', (tester) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('turn-off')));
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));

    expect(reloadCount, 0);
  });

  testWidgets('manual reload restarts the interval countdown', (tester) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await tester.pump(const Duration(minutes: 4));
    await tester.tap(find.byKey(const ValueKey<String>('manual-reload')));
    await tester.pump();

    expect(reloadCount, 1);

    await tester.pump(const Duration(minutes: 4, seconds: 59));
    expect(reloadCount, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(reloadCount, 2);
  });

  testWidgets('app lifecycle pause cancels timer until resumed', (
    tester,
  ) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));

    expect(reloadCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    await tester.pump();

    expect(reloadCount, 1);
  });

  testWidgets('dispose cancels a scheduled timer', (tester) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 5));

    expect(reloadCount, 0);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<void> Function() onReload,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _AutoRefreshHarness(onReload: onReload),
    ),
  );
}

class _AutoRefreshHarness extends StatefulWidget {
  const _AutoRefreshHarness({required this.onReload});

  final Future<void> Function() onReload;

  @override
  State<_AutoRefreshHarness> createState() => _AutoRefreshHarnessState();
}

class _AutoRefreshHarnessState extends State<_AutoRefreshHarness>
    with SalesAutoRefreshStateMixin<_AutoRefreshHarness> {
  @override
  Future<void> performSalesAutoRefreshReload() => widget.onReload();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text(salesAutoRefreshInterval?.label ?? 'off'),
          TextButton(
            key: const ValueKey<String>('set-five-minutes'),
            onPressed: () {
              setSalesAutoRefreshInterval(
                SalesAutoRefreshInterval.fiveMinutes,
              );
            },
            child: const Text('set 5'),
          ),
          TextButton(
            key: const ValueKey<String>('turn-off'),
            onPressed: () => setSalesAutoRefreshInterval(null),
            child: const Text('off'),
          ),
          TextButton(
            key: const ValueKey<String>('manual-reload'),
            onPressed: () => unawaited(reloadWithSalesAutoRefresh()),
            child: const Text('reload'),
          ),
        ],
      ),
    );
  }
}
