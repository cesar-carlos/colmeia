import 'dart:async';

import 'package:colmeia/features/sales/domain/entities/sales_auto_refresh_preference.dart';
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

    await _pumpAndAdvance(tester, const Duration(minutes: 30));

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
    await _pumpAndAdvance(tester, const Duration(minutes: 4, seconds: 59));

    expect(reloadCount, 0);

    await _pumpAndAdvance(tester, const Duration(seconds: 1));
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
    await _pumpAndAdvance(tester, const Duration(minutes: 5));
    await _pumpAndAdvance(tester, const Duration(minutes: 5));

    expect(reloadCount, 1);

    completer.complete();
    await tester.pump();
    await _pumpAndAdvance(tester, const Duration(minutes: 5));
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
    await _pumpAndAdvance(tester, const Duration(minutes: 5));

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
    await _pumpAndAdvance(tester, const Duration(minutes: 4));
    await tester.tap(find.byKey(const ValueKey<String>('manual-reload')));
    await tester.pump();

    expect(reloadCount, 1);

    await _pumpAndAdvance(tester, const Duration(minutes: 4, seconds: 59));
    expect(reloadCount, 1);

    await _pumpAndAdvance(tester, const Duration(seconds: 1));
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
    await _pumpAndAdvance(tester, const Duration(minutes: 5));

    expect(reloadCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(reloadCount, 1);
  });

  testWidgets('app lifecycle resume keeps the remaining visible-window delay', (
    tester,
  ) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await _pumpAndAdvance(tester, const Duration(minutes: 4));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _pumpAndAdvance(tester, const Duration(seconds: 10));

    expect(reloadCount, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await _pumpAndAdvance(tester, const Duration(seconds: 49));
    expect(reloadCount, 0);

    await _pumpAndAdvance(tester, const Duration(seconds: 1));
    await tester.pump();
    expect(reloadCount, 1);
  });

  testWidgets('restores the exact remaining delay from persisted preference', (
    tester,
  ) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      initialPreference: const SalesAutoRefreshPreference(
        interval: SalesAutoRefreshInterval.fiveMinutes,
        remainingDelay: Duration(minutes: 2),
      ),
    );

    await _pumpAndAdvance(tester, const Duration(minutes: 1, seconds: 59));
    expect(reloadCount, 0);

    await _pumpAndAdvance(tester, const Duration(seconds: 1));
    await tester.pump();

    expect(reloadCount, 1);
  });

  testWidgets('restores an overdue nextDueAt and refreshes immediately', (
    tester,
  ) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      initialPreference: SalesAutoRefreshPreference(
        interval: SalesAutoRefreshInterval.fiveMinutes,
        nextDueAt: DateTime(2026, 5, 18, 11, 59, 59),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(reloadCount, 1);
  });

  testWidgets('failed auto-refresh enters progressive backoff', (tester) async {
    var reloadCount = 0;
    var shouldSucceed = false;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      resolveCompletedAt: () {
        return shouldSucceed
            ? _harnessState(tester).currentSalesAutoRefreshTime
            : null;
      },
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();

    await _pumpAndAdvance(tester, const Duration(minutes: 4, seconds: 59));
    expect(reloadCount, 0);
    await _pumpAndAdvance(tester, const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    expect(reloadCount, 1);
    expect(_harnessState(tester).debugFailureStreak, 1);
    expect(_harnessState(tester).debugIsBackingOff, isTrue);

    await _pumpAndAdvance(tester, const Duration(minutes: 9, seconds: 59));
    expect(reloadCount, 1);

    shouldSucceed = true;
    await _pumpAndAdvance(tester, const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    expect(reloadCount, 2);
    expect(_harnessState(tester).debugFailureStreak, 0);
    expect(_harnessState(tester).debugIsBackingOff, isFalse);
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
  SalesAutoRefreshPreference initialPreference =
      SalesAutoRefreshPreference.disabled,
  DateTime? Function()? resolveCompletedAt,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _AutoRefreshHarness(
        onReload: onReload,
        initialPreference: initialPreference,
        resolveCompletedAt: resolveCompletedAt,
      ),
    ),
  );
}

Future<void> _pumpAndAdvance(
  WidgetTester tester,
  Duration duration,
) async {
  if (duration > Duration.zero) {
    _harnessState(tester).advanceAutoRefreshClock(duration);
  }
  await tester.pump(duration);
}

_AutoRefreshHarnessState _harnessState(WidgetTester tester) {
  return tester.state<_AutoRefreshHarnessState>(
    find.byType(_AutoRefreshHarness),
  );
}

class _AutoRefreshHarness extends StatefulWidget {
  const _AutoRefreshHarness({
    required this.onReload,
    required this.initialPreference,
    this.resolveCompletedAt,
  });

  final Future<void> Function() onReload;
  final SalesAutoRefreshPreference initialPreference;
  final DateTime? Function()? resolveCompletedAt;

  @override
  State<_AutoRefreshHarness> createState() => _AutoRefreshHarnessState();
}

class _AutoRefreshHarnessState extends State<_AutoRefreshHarness>
    with SalesAutoRefreshStateMixin<_AutoRefreshHarness> {
  DateTime _now = DateTime(2026, 5, 18, 12);

  @override
  void initState() {
    super.initState();
    restoreSalesAutoRefreshPreference(widget.initialPreference);
  }

  @override
  DateTime get currentSalesAutoRefreshTime => _now;

  int get debugFailureStreak => salesAutoRefreshFailureStreak;

  bool get debugIsBackingOff => salesAutoRefreshIsBackingOff;

  @override
  DateTime? resolveSalesAutoRefreshCompletedAt() {
    final resolver = widget.resolveCompletedAt;
    if (resolver != null) {
      return resolver();
    }
    return currentSalesAutoRefreshTime;
  }

  void advanceAutoRefreshClock(Duration duration) {
    _now = _now.add(duration);
  }

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
