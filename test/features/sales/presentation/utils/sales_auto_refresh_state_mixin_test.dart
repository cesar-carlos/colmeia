import 'dart:async';

import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_persistence.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
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

  testWidgets('does not schedule when auto-refresh is unsupported', (
    tester,
  ) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      supportsAutoRefresh: false,
      restoredSnapshot: const AutoRefreshSnapshot(
        option: SalesAutoRefreshOptions.fiveMinutes,
      ),
    );

    await _pumpAndAdvance(tester, const Duration(minutes: 30));

    expect(reloadCount, 0);
  });

  testWidgets('does not schedule when auto-refresh cannot run now', (
    tester,
  ) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      canScheduleAutoRefresh: false,
      restoredSnapshot: const AutoRefreshSnapshot(
        option: SalesAutoRefreshOptions.fiveMinutes,
      ),
    );

    await _pumpAndAdvance(tester, const Duration(minutes: 30));

    expect(reloadCount, 0);
  });

  testWidgets('pauses without clearing the selected option', (tester) async {
    final persistence = _FakeAutoRefreshStatePersistence(
      restoredSnapshot: AutoRefreshSnapshot(
        option: SalesAutoRefreshOptions.fiveMinutes,
        lastSuccessfulRefreshAt: DateTime(2026, 5, 18, 11, 55),
        remainingDelay: const Duration(minutes: 2),
      ),
    );

    await _pumpHarness(
      tester,
      onReload: () async {},
      restoredSnapshot: persistence.restoredSnapshot,
      canScheduleAutoRefresh: false,
      persistence: persistence,
      pauseReasonResolver: () => AutoRefreshPauseReason.noEligibleSelection,
    );

    expect(
      _harnessState(tester).autoRefreshOption,
      SalesAutoRefreshOptions.fiveMinutes,
    );
    expect(_harnessState(tester).debugIsPaused, isTrue);
    expect(
      _harnessState(tester).debugPauseReason,
      AutoRefreshPauseReason.noEligibleSelection,
    );
    expect(
      persistence.persistedSnapshots.every(
        (snapshot) => snapshot.option != null,
      ),
      isTrue,
    );
  });

  testWidgets('resumes with the preserved remaining delay', (tester) async {
    var reloadCount = 0;
    var canSchedule = false;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      restoredSnapshot: const AutoRefreshSnapshot(
        option: SalesAutoRefreshOptions.fiveMinutes,
        remainingDelay: Duration(minutes: 2),
      ),
      canScheduleResolver: () => canSchedule,
      pauseReasonResolver: () =>
          canSchedule ? null : AutoRefreshPauseReason.noEligibleSelection,
    );

    expect(_harnessState(tester).debugIsPaused, isTrue);

    _harnessState(tester).advanceAutoRefreshClock(const Duration(minutes: 1));
    canSchedule = true;
    _harnessState(tester).refreshScheduler();
    await tester.pump();

    expect(_harnessState(tester).debugIsPaused, isFalse);

    await _pumpAndAdvance(tester, const Duration(minutes: 1, seconds: 59));
    expect(reloadCount, 0);

    await _pumpAndAdvance(tester, const Duration(seconds: 1));
    await tester.pump();

    expect(reloadCount, 1);
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

  testWidgets('queues the elapsed auto-refresh tick while reload is active', (
    tester,
  ) async {
    var reloadCount = 0;
    final completer = Completer<void>();

    await _pumpHarness(
      tester,
      onReload: () {
        reloadCount += 1;
        if (reloadCount == 1) {
          return completer.future;
        }
        return Future<void>.value();
      },
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await _pumpAndAdvance(tester, const Duration(minutes: 5));
    await _pumpAndAdvance(tester, const Duration(minutes: 5));

    expect(reloadCount, 1);

    completer.complete();
    await tester.pump();
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

  testWidgets(
    'route observer pauses scheduling until the route is visible again',
    (
      tester,
    ) async {
      var reloadCount = 0;
      final routeObserver = RouteObserver<ModalRoute<void>>();

      await _pumpHarness(
        tester,
        onReload: () async => reloadCount += 1,
        routeObserver: routeObserver,
      );

      await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
      await tester.pump();
      await _pumpAndAdvance(tester, const Duration(minutes: 4));

      unawaited(
        Navigator.of(_harnessState(tester).context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('next')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _pumpAndAdvance(tester, const Duration(minutes: 1));

      expect(reloadCount, 0);

      Navigator.of(tester.element(find.text('next'))).pop();
      await tester.pumpAndSettle();
      await tester.pump();

      expect(reloadCount, 1);
    },
  );

  testWidgets('restores the exact remaining delay from persisted snapshot', (
    tester,
  ) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      restoredSnapshot: const AutoRefreshSnapshot(
        option: SalesAutoRefreshOptions.fiveMinutes,
        remainingDelay: Duration(minutes: 2),
      ),
    );

    await _pumpAndAdvance(tester, const Duration(minutes: 1, seconds: 59));
    expect(reloadCount, 0);

    await _pumpAndAdvance(tester, const Duration(seconds: 1));
    await tester.pump();

    expect(reloadCount, 1);
  });

  testWidgets(
    'route observer can keep scheduling while the route is hidden when explicitly allowed',
    (tester) async {
      var reloadCount = 0;
      final routeObserver = RouteObserver<ModalRoute<void>>();

      await _pumpHarness(
        tester,
        onReload: () async => reloadCount += 1,
        routeObserver: routeObserver,
        allowRouteHiddenAutoRefresh: true,
      );

      await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
      await tester.pump();
      await _pumpAndAdvance(tester, const Duration(minutes: 4));

      unawaited(
        Navigator.of(_harnessState(tester).context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('next')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _pumpAndAdvance(tester, const Duration(minutes: 1));
      await tester.pump();

      expect(reloadCount, 1);
    },
  );

  testWidgets('restores an overdue nextDueAt and refreshes immediately', (
    tester,
  ) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      restoredSnapshot: AutoRefreshSnapshot(
        option: SalesAutoRefreshOptions.fiveMinutes,
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
            ? _harnessState(tester).currentAutoRefreshTime
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

  testWidgets('cancelled auto-refresh does not enter backoff', (tester) async {
    var reloadCount = 0;

    await _pumpHarness(
      tester,
      onReload: () async => reloadCount += 1,
      resolveReloadResult: () => const AutoRefreshReloadResult.cancelled(),
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await _pumpAndAdvance(tester, const Duration(minutes: 5));
    await tester.pump();
    await tester.pump();

    expect(reloadCount, 1);
    expect(_harnessState(tester).debugFailureStreak, 0);
    expect(_harnessState(tester).debugIsBackingOff, isFalse);
  });

  testWidgets('persists snapshot updates when state changes', (tester) async {
    final persistence = _FakeAutoRefreshStatePersistence();

    await _pumpHarness(
      tester,
      onReload: () async {},
      persistence: persistence,
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();

    expect(persistence.persistedSnapshots, hasLength(1));
    expect(
      persistence.persistedSnapshots.single.option,
      SalesAutoRefreshOptions.fiveMinutes,
    );
  });

  testWidgets(
    'logging hooks receive restore, schedule, success and backoff events',
    (
      tester,
    ) async {
      var shouldSucceed = true;
      final logs = _AutoRefreshLogRecorder();

      await _pumpHarness(
        tester,
        onReload: () async {},
        logRecorder: logs,
        restoredSnapshot: const AutoRefreshSnapshot(
          option: SalesAutoRefreshOptions.fiveMinutes,
          remainingDelay: Duration(minutes: 5),
        ),
        resolveCompletedAt: () {
          return shouldSucceed
              ? _harnessState(tester).currentAutoRefreshTime
              : null;
        },
      );

      expect(logs.infoMessages, contains('Auto refresh restored'));
      expect(logs.infoMessages, contains('Auto refresh scheduled'));

      await _pumpAndAdvance(tester, const Duration(minutes: 5));
      await tester.pump();
      await tester.pump();

      expect(logs.infoMessages, contains('Auto refresh triggered'));
      expect(logs.infoMessages, contains('Auto refresh succeeded'));

      shouldSucceed = false;
      await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
      await tester.pump();
      await _pumpAndAdvance(tester, const Duration(minutes: 5));
      await tester.pump();
      await tester.pump();

      expect(
        logs.warningMessages,
        contains('Auto refresh failed; backoff scheduled'),
      );
    },
  );

  testWidgets('logging hooks receive skip event while a reload is active', (
    tester,
  ) async {
    final completer = Completer<void>();
    final logs = _AutoRefreshLogRecorder();

    await _pumpHarness(
      tester,
      onReload: () => completer.future,
      logRecorder: logs,
    );

    await tester.tap(find.byKey(const ValueKey<String>('set-five-minutes')));
    await tester.pump();
    await _pumpAndAdvance(tester, const Duration(minutes: 4));
    await tester.tap(find.byKey(const ValueKey<String>('manual-reload')));
    await tester.pump();
    await _pumpAndAdvance(tester, const Duration(minutes: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(
      logs.infoMessages,
      contains('Auto refresh skipped while reload is active'),
    );

    completer.complete();
    await tester.pump();
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

  testWidgets('dispose unsubscribes from the observer used during subscribe', (
    tester,
  ) async {
    final subscribedObserver = _TrackingRouteObserver();
    final disposeObserver = _TrackingRouteObserver();
    var currentObserver = subscribedObserver;

    await _pumpHarness(
      tester,
      onReload: () async {},
      routeObserver: subscribedObserver,
      routeObserverResolver: () => currentObserver,
    );

    expect(subscribedObserver.subscribeCount, 1);

    currentObserver = disposeObserver;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(subscribedObserver.unsubscribeCount, 1);
    expect(disposeObserver.unsubscribeCount, 0);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Future<void> Function() onReload,
  AutoRefreshSnapshot restoredSnapshot = AutoRefreshSnapshot.disabled,
  _FakeAutoRefreshStatePersistence? persistence,
  bool supportsAutoRefresh = true,
  bool canScheduleAutoRefresh = true,
  bool Function()? canScheduleResolver,
  RouteObserver<ModalRoute<void>>? routeObserver,
  RouteObserver<ModalRoute<void>>? Function()? routeObserverResolver,
  bool allowRouteHiddenAutoRefresh = false,
  _AutoRefreshLogRecorder? logRecorder,
  DateTime? Function()? resolveCompletedAt,
  AutoRefreshReloadResult Function()? resolveReloadResult,
  AutoRefreshPauseReason? Function()? pauseReasonResolver,
}) async {
  final resolvedPersistence =
      (persistence ??
            _FakeAutoRefreshStatePersistence(
              restoredSnapshot: restoredSnapshot,
            ))
        ..restoredSnapshot = restoredSnapshot;

  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: routeObserver == null
          ? const <NavigatorObserver>[]
          : <NavigatorObserver>[routeObserver],
      home: _AutoRefreshHarness(
        onReload: onReload,
        persistence: resolvedPersistence,
        supportsAutoRefresh: supportsAutoRefresh,
        canScheduleAutoRefresh: canScheduleAutoRefresh,
        canScheduleResolver: canScheduleResolver,
        routeObserver: routeObserver,
        routeObserverResolver: routeObserverResolver,
        allowRouteHiddenAutoRefresh: allowRouteHiddenAutoRefresh,
        logRecorder: logRecorder,
        resolveCompletedAt: resolveCompletedAt,
        resolveReloadResult: resolveReloadResult,
        pauseReasonResolver: pauseReasonResolver,
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
    find.byType(_AutoRefreshHarness, skipOffstage: false),
  );
}

class _AutoRefreshHarness extends StatefulWidget {
  const _AutoRefreshHarness({
    required this.onReload,
    required this.persistence,
    required this.supportsAutoRefresh,
    required this.canScheduleAutoRefresh,
    this.canScheduleResolver,
    this.routeObserver,
    this.routeObserverResolver,
    this.allowRouteHiddenAutoRefresh = false,
    this.logRecorder,
    this.resolveCompletedAt,
    this.resolveReloadResult,
    this.pauseReasonResolver,
  });

  final Future<void> Function() onReload;
  final _FakeAutoRefreshStatePersistence persistence;
  final bool supportsAutoRefresh;
  final bool canScheduleAutoRefresh;
  final bool Function()? canScheduleResolver;
  final RouteObserver<ModalRoute<void>>? routeObserver;
  final RouteObserver<ModalRoute<void>>? Function()? routeObserverResolver;
  final bool allowRouteHiddenAutoRefresh;
  final _AutoRefreshLogRecorder? logRecorder;
  final DateTime? Function()? resolveCompletedAt;
  final AutoRefreshReloadResult Function()? resolveReloadResult;
  final AutoRefreshPauseReason? Function()? pauseReasonResolver;

  @override
  State<_AutoRefreshHarness> createState() => _AutoRefreshHarnessState();
}

class _AutoRefreshHarnessState extends State<_AutoRefreshHarness>
    with AutoRefreshStateMixin<_AutoRefreshHarness> {
  DateTime _now = DateTime(2026, 5, 18, 12);

  @override
  bool get supportsAutoRefresh => widget.supportsAutoRefresh;

  @override
  bool get canScheduleAutoRefresh =>
      widget.canScheduleResolver?.call() ?? widget.canScheduleAutoRefresh;

  @override
  AutoRefreshStatePersistence get autoRefreshStatePersistence =>
      widget.persistence;

  @override
  RouteObserver<ModalRoute<void>>? get autoRefreshRouteObserver =>
      widget.routeObserverResolver?.call() ?? widget.routeObserver;

  @override
  bool get canAutoRefreshWhileRouteHidden => widget.allowRouteHiddenAutoRefresh;

  @override
  DateTime get currentAutoRefreshTime => _now;

  int get debugFailureStreak => autoRefreshFailureStreak;

  bool get debugIsBackingOff => autoRefreshIsBackingOff;

  bool get debugIsPaused => autoRefreshIsPaused;

  AutoRefreshPauseReason? get debugPauseReason => autoRefreshPauseReason;

  @override
  void logAutoRefreshInfo(String message, Map<String, Object?> context) {
    widget.logRecorder?.recordInfo(message, context);
  }

  @override
  void logAutoRefreshWarning(String message, Map<String, Object?> context) {
    widget.logRecorder?.recordWarning(message, context);
  }

  @override
  DateTime? resolveAutoRefreshCompletedAt() {
    final resolver = widget.resolveCompletedAt;
    if (resolver != null) {
      return resolver();
    }
    return currentAutoRefreshTime;
  }

  @override
  AutoRefreshReloadResult resolveAutoRefreshReloadResult() {
    final resolver = widget.resolveReloadResult;
    if (resolver != null) {
      return resolver();
    }
    return super.resolveAutoRefreshReloadResult();
  }

  @override
  AutoRefreshPauseReason? resolveAutoRefreshPauseReason() {
    return widget.pauseReasonResolver?.call();
  }

  void advanceAutoRefreshClock(Duration duration) {
    _now = _now.add(duration);
  }

  void refreshScheduler() {
    refreshAutoRefreshScheduling();
  }

  @override
  Future<void> performAutoRefreshReload() => widget.onReload();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text(autoRefreshOption?.id ?? 'off'),
          TextButton(
            key: const ValueKey<String>('set-five-minutes'),
            onPressed: () {
              setAutoRefreshOption(SalesAutoRefreshOptions.fiveMinutes);
            },
            child: const Text('set 5'),
          ),
          TextButton(
            key: const ValueKey<String>('turn-off'),
            onPressed: disableAutoRefresh,
            child: const Text('off'),
          ),
          TextButton(
            key: const ValueKey<String>('manual-reload'),
            onPressed: () => unawaited(reloadWithAutoRefresh()),
            child: const Text('reload'),
          ),
        ],
      ),
    );
  }
}

class _FakeAutoRefreshStatePersistence implements AutoRefreshStatePersistence {
  _FakeAutoRefreshStatePersistence({
    this.restoredSnapshot = AutoRefreshSnapshot.disabled,
  });

  AutoRefreshSnapshot restoredSnapshot;

  final List<AutoRefreshSnapshot> persistedSnapshots = <AutoRefreshSnapshot>[];

  @override
  AutoRefreshSnapshot restoreAutoRefreshSnapshot() => restoredSnapshot;

  @override
  Future<void> persistAutoRefreshSnapshot(AutoRefreshSnapshot snapshot) async {
    persistedSnapshots.add(snapshot);
  }
}

class _AutoRefreshLogRecorder {
  final List<String> infoMessages = <String>[];
  final List<String> warningMessages = <String>[];
  final List<Map<String, Object?>> infoContexts = <Map<String, Object?>>[];
  final List<Map<String, Object?>> warningContexts = <Map<String, Object?>>[];

  void recordInfo(String message, Map<String, Object?> context) {
    infoMessages.add(message);
    infoContexts.add(context);
  }

  void recordWarning(String message, Map<String, Object?> context) {
    warningMessages.add(message);
    warningContexts.add(context);
  }
}

class _TrackingRouteObserver extends RouteObserver<ModalRoute<void>> {
  int subscribeCount = 0;
  int unsubscribeCount = 0;

  @override
  void subscribe(RouteAware routeAware, ModalRoute<void> route) {
    subscribeCount += 1;
    super.subscribe(routeAware, route);
  }

  @override
  void unsubscribe(RouteAware routeAware) {
    unsubscribeCount += 1;
    super.unsubscribe(routeAware);
  }
}
