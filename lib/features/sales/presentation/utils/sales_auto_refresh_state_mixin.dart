import 'dart:async';

import 'package:colmeia/app/router/app_shell_route_observer.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/sales/domain/entities/sales_auto_refresh_preference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class SalesAutoRefreshUiState {
  const SalesAutoRefreshUiState({
    this.interval,
    this.lastUpdatedAt,
    this.nextDueAt,
    this.remainingDelay,
    this.isBackingOff = false,
    this.failureStreak = 0,
  });

  final SalesAutoRefreshInterval? interval;
  final DateTime? lastUpdatedAt;
  final DateTime? nextDueAt;
  final Duration? remainingDelay;
  final bool isBackingOff;
  final int failureStreak;

  SalesAutoRefreshUiState copyWith({
    Object? interval = _sentinel,
    Object? lastUpdatedAt = _sentinel,
    Object? nextDueAt = _sentinel,
    Object? remainingDelay = _sentinel,
    Object? isBackingOff = _sentinel,
    Object? failureStreak = _sentinel,
  }) {
    return SalesAutoRefreshUiState(
      interval: identical(interval, _sentinel)
          ? this.interval
          : interval as SalesAutoRefreshInterval?,
      lastUpdatedAt: identical(lastUpdatedAt, _sentinel)
          ? this.lastUpdatedAt
          : lastUpdatedAt as DateTime?,
      nextDueAt: identical(nextDueAt, _sentinel)
          ? this.nextDueAt
          : nextDueAt as DateTime?,
      remainingDelay: identical(remainingDelay, _sentinel)
          ? this.remainingDelay
          : remainingDelay as Duration?,
      isBackingOff:
          identical(isBackingOff, _sentinel)
              ? this.isBackingOff
              : (isBackingOff as bool?) ?? false,
      failureStreak:
          identical(failureStreak, _sentinel)
              ? this.failureStreak
              : (failureStreak as int?) ?? 0,
    );
  }
}

mixin SalesAutoRefreshStateMixin<T extends StatefulWidget> on State<T> {
  late final _SalesAutoRefreshAppLifecycleObserver
  _salesAutoRefreshAppLifecycleObserver;
  late final _SalesAutoRefreshRouteAware _salesAutoRefreshRouteAware;
  late final ValueNotifier<SalesAutoRefreshUiState>
  _salesAutoRefreshUiStateNotifier;
  Timer? _salesAutoRefreshTimer;
  DateTime? _salesAutoRefreshNextDueAt;
  Duration? _salesAutoRefreshRemainingDelay;
  int _salesAutoRefreshFailureStreak = 0;
  int _salesAutoRefreshActiveReloads = 0;
  bool _salesAutoRefreshAppVisible = true;
  bool _salesAutoRefreshRouteVisible = true;
  bool _salesAutoRefreshRouteObserverSubscribed = false;

  ValueListenable<SalesAutoRefreshUiState> get salesAutoRefreshStateListenable =>
      _salesAutoRefreshUiStateNotifier;

  SalesAutoRefreshInterval? get salesAutoRefreshInterval =>
      _salesAutoRefreshUiStateNotifier.value.interval;

  DateTime? get salesAutoRefreshLastUpdatedAt =>
      _salesAutoRefreshUiStateNotifier.value.lastUpdatedAt;

  @protected
  DateTime? get salesAutoRefreshNextDueAt => _salesAutoRefreshNextDueAt;

  @protected
  Duration? get salesAutoRefreshRemainingDelay =>
      _resolveSalesAutoRefreshRemainingDelay();

  @protected
  int get salesAutoRefreshFailureStreak => _salesAutoRefreshFailureStreak;

  @protected
  bool get salesAutoRefreshIsBackingOff => _salesAutoRefreshFailureStreak > 0;

  @protected
  bool get canScheduleSalesAutoRefresh => true;

  @protected
  bool get rebuildOnSalesAutoRefreshStateChange => true;

  @protected
  Future<void> performSalesAutoRefreshReload();

  @protected
  DateTime? resolveSalesAutoRefreshCompletedAt() => DateTime.now();

  @protected
  DateTime get currentSalesAutoRefreshTime => DateTime.now();

  @protected
  void didUpdateSalesAutoRefreshUiState(SalesAutoRefreshUiState state) {}

  @override
  void initState() {
    super.initState();
    _salesAutoRefreshUiStateNotifier = ValueNotifier<SalesAutoRefreshUiState>(
      const SalesAutoRefreshUiState(),
    );
    _salesAutoRefreshAppLifecycleObserver =
        _SalesAutoRefreshAppLifecycleObserver(
          onVisibilityChanged: _setSalesAutoRefreshAppVisibility,
        );
    _salesAutoRefreshRouteAware = _SalesAutoRefreshRouteAware(
      onVisibilityChanged: _setSalesAutoRefreshRouteVisibility,
    );
    WidgetsBinding.instance.addObserver(_salesAutoRefreshAppLifecycleObserver);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_salesAutoRefreshRouteObserverSubscribed) {
      return;
    }
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      appShellRouteObserver.subscribe(_salesAutoRefreshRouteAware, route);
      _salesAutoRefreshRouteObserverSubscribed = true;
    }
  }

  @protected
  Future<void> reloadWithSalesAutoRefresh({bool force = false}) async {
    if (!force && _salesAutoRefreshActiveReloads > 0) {
      return;
    }
    _cancelSalesAutoRefreshTimer();
    await _trackSalesAutoRefreshReload(performSalesAutoRefreshReload);
  }

  @protected
  void disableSalesAutoRefresh() {
    _cancelSalesAutoRefreshTimer();
    _salesAutoRefreshNextDueAt = null;
    _salesAutoRefreshRemainingDelay = null;
    _salesAutoRefreshFailureStreak = 0;
    if (salesAutoRefreshInterval == null) {
      _publishSalesAutoRefreshUiState();
      return;
    }
    _publishSalesAutoRefreshUiState(
      interval: null,
    );
  }

  @protected
  void setSalesAutoRefreshInterval(SalesAutoRefreshInterval? interval) {
    if (salesAutoRefreshInterval == interval) {
      return;
    }
    _salesAutoRefreshFailureStreak = 0;
    if (interval == null) {
      _cancelSalesAutoRefreshTimer();
      _salesAutoRefreshRemainingDelay = null;
      _salesAutoRefreshNextDueAt = null;
    } else {
      _setSalesAutoRefreshNextCycle(
        delay: interval.duration,
        anchorTime: currentSalesAutoRefreshTime,
      );
    }
    _publishSalesAutoRefreshUiState(
      interval: interval,
    );
    _refreshSalesAutoRefreshScheduling(resetDelayIfIdle: false);
  }

  @protected
  void restoreSalesAutoRefreshPreference(SalesAutoRefreshPreference preference) {
    final interval = preference.interval;
    _salesAutoRefreshFailureStreak = preference.failureStreak;
    if (interval == null) {
      _salesAutoRefreshNextDueAt = null;
      _salesAutoRefreshRemainingDelay = null;
    } else if (preference.remainingDelay != null) {
      _setSalesAutoRefreshNextCycle(
        delay: preference.remainingDelay!,
        anchorTime: currentSalesAutoRefreshTime,
      );
    } else if (preference.nextDueAt != null) {
      _salesAutoRefreshNextDueAt = preference.nextDueAt;
      _salesAutoRefreshRemainingDelay =
          _resolveSalesAutoRefreshRemainingDelay();
    } else {
      final fallbackDelay = _resolveRestoredFallbackDelay(
        interval: interval,
        lastSuccessfulRefreshAt: preference.lastSuccessfulRefreshAt,
      );
      _setSalesAutoRefreshNextCycle(
        delay: fallbackDelay,
        anchorTime: currentSalesAutoRefreshTime,
      );
    }
    _publishSalesAutoRefreshUiState(
      interval: interval,
      lastUpdatedAt: preference.lastSuccessfulRefreshAt,
      notifyExternal: false,
    );
    _logSalesAutoRefreshEvent(
      'Sales auto refresh restored',
      <String, Object?>{
        'interval': interval?.name,
        'lastSuccessfulRefreshAt':
            preference.lastSuccessfulRefreshAt?.toIso8601String(),
        'nextDueAt': _salesAutoRefreshNextDueAt?.toIso8601String(),
        'remainingMs': _resolveSalesAutoRefreshRemainingDelay()
            ?.inMilliseconds,
        'failureStreak': _salesAutoRefreshFailureStreak,
      },
    );
    _refreshSalesAutoRefreshScheduling(resetDelayIfIdle: false);
  }

  @protected
  void recordSalesAutoRefreshSuccessfulReload(DateTime refreshedAt) {
    _salesAutoRefreshFailureStreak = 0;
    final interval = salesAutoRefreshInterval;
    if (interval == null) {
      _salesAutoRefreshNextDueAt = null;
      _salesAutoRefreshRemainingDelay = null;
    } else {
      _setSalesAutoRefreshNextCycle(
        delay: interval.duration,
        anchorTime: currentSalesAutoRefreshTime,
      );
    }
    _publishSalesAutoRefreshUiState(
      lastUpdatedAt: refreshedAt,
    );
    _logSalesAutoRefreshEvent(
      'Sales auto refresh succeeded',
      <String, Object?>{
        'interval': interval?.name,
        'refreshedAt': refreshedAt.toIso8601String(),
        'nextDueAt': _salesAutoRefreshNextDueAt?.toIso8601String(),
      },
    );
    _refreshSalesAutoRefreshScheduling(resetDelayIfIdle: false);
  }

  @protected
  void refreshSalesAutoRefreshScheduling({bool resetDelayIfIdle = false}) {
    _refreshSalesAutoRefreshScheduling(resetDelayIfIdle: resetDelayIfIdle);
  }

  void _setSalesAutoRefreshAppVisibility(bool visible) {
    if (_salesAutoRefreshAppVisible == visible) {
      return;
    }
    _salesAutoRefreshAppVisible = visible;
    _syncSalesAutoRefreshTimerWithVisibility();
  }

  void _setSalesAutoRefreshRouteVisibility(bool visible) {
    if (_salesAutoRefreshRouteVisible == visible) {
      return;
    }
    _salesAutoRefreshRouteVisible = visible;
    _syncSalesAutoRefreshTimerWithVisibility();
  }

  void _syncSalesAutoRefreshTimerWithVisibility() {
    _refreshSalesAutoRefreshScheduling(resetDelayIfIdle: false);
  }

  Future<void> _handleSalesAutoRefreshTick() async {
    _cancelSalesAutoRefreshTimer();
    if (!mounted) {
      return;
    }
    if (!_canRunSalesAutoRefreshTimer) {
      _refreshSalesAutoRefreshScheduling(resetDelayIfIdle: false);
      return;
    }
    if (_salesAutoRefreshActiveReloads > 0) {
      _logSalesAutoRefreshEvent(
        'Sales auto refresh skipped while reload is active',
        <String, Object?>{
          'activeReloads': _salesAutoRefreshActiveReloads,
          'interval': salesAutoRefreshInterval?.name,
        },
      );
      return;
    }
    _logSalesAutoRefreshEvent(
      'Sales auto refresh triggered',
      <String, Object?>{
        'interval': salesAutoRefreshInterval?.name,
        'failureStreak': _salesAutoRefreshFailureStreak,
      },
    );
    try {
      await _trackSalesAutoRefreshReload(performSalesAutoRefreshReload);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'sales auto refresh',
        ),
      );
    }
  }

  Future<void> _trackSalesAutoRefreshReload(
    Future<void> Function() reload,
  ) async {
    _salesAutoRefreshActiveReloads += 1;
    try {
      await reload();
      final completedAt = resolveSalesAutoRefreshCompletedAt();
      if (completedAt != null) {
        recordSalesAutoRefreshSuccessfulReload(completedAt);
      } else {
        _recordSalesAutoRefreshFailure();
      }
    } on Object {
      _recordSalesAutoRefreshFailure();
      rethrow;
    } finally {
      _salesAutoRefreshActiveReloads -= 1;
      _refreshSalesAutoRefreshScheduling(resetDelayIfIdle: false);
    }
  }

  bool get _canRunSalesAutoRefreshTimer =>
      mounted &&
      _salesAutoRefreshAppVisible &&
      _salesAutoRefreshRouteVisible &&
      canScheduleSalesAutoRefresh;

  void _refreshSalesAutoRefreshScheduling({required bool resetDelayIfIdle}) {
    if (!_canRunSalesAutoRefreshTimer) {
      _pauseSalesAutoRefreshTimer();
      return;
    }
    final interval = salesAutoRefreshInterval;
    if (interval == null) {
      _cancelSalesAutoRefreshTimer();
      _salesAutoRefreshNextDueAt = null;
      _salesAutoRefreshRemainingDelay = null;
      _publishSalesAutoRefreshUiState(notifyExternal: false);
      return;
    }
    if (resetDelayIfIdle || _salesAutoRefreshNextDueAt == null) {
      _setSalesAutoRefreshNextCycle(
        delay: _resolveScheduledDelay(interval),
        anchorTime: currentSalesAutoRefreshTime,
      );
      _publishSalesAutoRefreshUiState();
    }
    _scheduleSalesAutoRefreshTimer();
  }

  void _scheduleSalesAutoRefreshTimer() {
    _cancelSalesAutoRefreshTimer();
    final nextDueAt = _salesAutoRefreshNextDueAt;
    if (nextDueAt == null || !_canRunSalesAutoRefreshTimer) {
      return;
    }
    final remainingDelay = nextDueAt.difference(currentSalesAutoRefreshTime);
    if (remainingDelay <= Duration.zero) {
      scheduleMicrotask(() {
        if (!mounted) {
          return;
        }
        unawaited(_handleSalesAutoRefreshTick());
      });
      return;
    }
    _salesAutoRefreshRemainingDelay = remainingDelay;
    _salesAutoRefreshTimer = Timer(remainingDelay, () {
      unawaited(_handleSalesAutoRefreshTick());
    });
    _logSalesAutoRefreshEvent(
      'Sales auto refresh scheduled',
      <String, Object?>{
        'interval': salesAutoRefreshInterval?.name,
        'nextDueAt': nextDueAt.toIso8601String(),
        'remainingMs': remainingDelay.inMilliseconds,
        'failureStreak': _salesAutoRefreshFailureStreak,
      },
    );
  }

  void _cancelSalesAutoRefreshTimer() {
    _salesAutoRefreshTimer?.cancel();
    _salesAutoRefreshTimer = null;
  }

  void _pauseSalesAutoRefreshTimer() {
    _cancelSalesAutoRefreshTimer();
    _salesAutoRefreshRemainingDelay = _resolveSalesAutoRefreshRemainingDelay();
    _publishSalesAutoRefreshUiState();
  }

  void _recordSalesAutoRefreshFailure() {
    final interval = salesAutoRefreshInterval;
    if (interval == null) {
      _logSalesAutoRefreshEvent(
        'Sales auto refresh failed with scheduling disabled',
      );
      return;
    }
    _salesAutoRefreshFailureStreak += 1;
    final backoffDelay = _resolveBackoffDelay(
      interval: interval,
      failureStreak: _salesAutoRefreshFailureStreak,
    );
    _setSalesAutoRefreshNextCycle(
      delay: backoffDelay,
      anchorTime: currentSalesAutoRefreshTime,
    );
    _publishSalesAutoRefreshUiState();
    _logSalesAutoRefreshEvent(
      'Sales auto refresh failed; backoff scheduled',
      <String, Object?>{
        'interval': interval.name,
        'failureStreak': _salesAutoRefreshFailureStreak,
        'nextDueAt': _salesAutoRefreshNextDueAt?.toIso8601String(),
        'remainingMs': _salesAutoRefreshRemainingDelay?.inMilliseconds,
      },
      true,
    );
  }

  void _setSalesAutoRefreshNextCycle({
    required Duration delay,
    required DateTime anchorTime,
  }) {
    final normalizedDelay = delay <= Duration.zero ? Duration.zero : delay;
    _salesAutoRefreshRemainingDelay = normalizedDelay;
    _salesAutoRefreshNextDueAt = anchorTime.add(normalizedDelay);
  }

  Duration _resolveScheduledDelay(SalesAutoRefreshInterval interval) {
    if (_salesAutoRefreshFailureStreak <= 0) {
      return interval.duration;
    }
    return _resolveBackoffDelay(
      interval: interval,
      failureStreak: _salesAutoRefreshFailureStreak,
    );
  }

  Duration _resolveBackoffDelay({
    required SalesAutoRefreshInterval interval,
    required int failureStreak,
  }) {
    final multiplier = switch (failureStreak) {
      <= 0 => 1,
      1 => 2,
      2 => 4,
      _ => 8,
    };
    return interval.duration * multiplier;
  }

  Duration _resolveRestoredFallbackDelay({
    required SalesAutoRefreshInterval interval,
    required DateTime? lastSuccessfulRefreshAt,
  }) {
    if (lastSuccessfulRefreshAt == null) {
      return interval.duration;
    }
    final dueAt = lastSuccessfulRefreshAt.add(interval.duration);
    final remaining = dueAt.difference(currentSalesAutoRefreshTime);
    return remaining <= Duration.zero ? Duration.zero : remaining;
  }

  Duration? _resolveSalesAutoRefreshRemainingDelay() {
    final nextDueAt = _salesAutoRefreshNextDueAt;
    if (nextDueAt == null) {
      return _salesAutoRefreshRemainingDelay;
    }
    final remaining = nextDueAt.difference(currentSalesAutoRefreshTime);
    return remaining <= Duration.zero ? Duration.zero : remaining;
  }

  void _publishSalesAutoRefreshUiState({
    Object? interval = _sentinel,
    Object? lastUpdatedAt = _sentinel,
    bool notifyExternal = true,
  }) {
    final current = _salesAutoRefreshUiStateNotifier.value;
    final nextState = current.copyWith(
      interval: identical(interval, _sentinel)
          ? current.interval
          : interval as SalesAutoRefreshInterval?,
      lastUpdatedAt: identical(lastUpdatedAt, _sentinel)
          ? current.lastUpdatedAt
          : lastUpdatedAt as DateTime?,
      nextDueAt: _salesAutoRefreshNextDueAt,
      remainingDelay: _resolveSalesAutoRefreshRemainingDelay(),
      isBackingOff: _salesAutoRefreshFailureStreak > 0,
      failureStreak: _salesAutoRefreshFailureStreak,
    );
    _setSalesAutoRefreshUiState(nextState, notifyExternal: notifyExternal);
  }

  void _setSalesAutoRefreshUiState(
    SalesAutoRefreshUiState nextState, {
    bool notifyExternal = true,
  }) {
    final previousState = _salesAutoRefreshUiStateNotifier.value;
    if (previousState.interval == nextState.interval &&
        previousState.lastUpdatedAt == nextState.lastUpdatedAt &&
        previousState.nextDueAt == nextState.nextDueAt &&
        previousState.remainingDelay == nextState.remainingDelay &&
        previousState.isBackingOff == nextState.isBackingOff &&
        previousState.failureStreak == nextState.failureStreak) {
      return;
    }
    _salesAutoRefreshUiStateNotifier.value = nextState;
    if (notifyExternal) {
      didUpdateSalesAutoRefreshUiState(nextState);
    }
    if (rebuildOnSalesAutoRefreshStateChange && mounted) {
      setState(() {});
    }
  }

  void _logSalesAutoRefreshEvent(
    String message, [
    Map<String, Object?> context = const <String, Object?>{},
    bool warning = false,
  ]) {
    final payload = <String, Object?>{
      'owner': '$T',
      'interval': salesAutoRefreshInterval?.name,
      ...context,
    };
    if (warning) {
      AppLogger.warning(message, context: payload);
      return;
    }
    AppLogger.info(message, context: payload);
  }

  @override
  void dispose() {
    if (_salesAutoRefreshRouteObserverSubscribed) {
      appShellRouteObserver.unsubscribe(_salesAutoRefreshRouteAware);
    }
    WidgetsBinding.instance.removeObserver(
      _salesAutoRefreshAppLifecycleObserver,
    );
    _cancelSalesAutoRefreshTimer();
    _salesAutoRefreshUiStateNotifier.dispose();
    super.dispose();
  }
}

class _SalesAutoRefreshAppLifecycleObserver extends WidgetsBindingObserver {
  _SalesAutoRefreshAppLifecycleObserver({required this.onVisibilityChanged});

  final ValueChanged<bool> onVisibilityChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };
    onVisibilityChanged(visible);
  }
}

class _SalesAutoRefreshRouteAware extends RouteAware {
  _SalesAutoRefreshRouteAware({required this.onVisibilityChanged});

  final ValueChanged<bool> onVisibilityChanged;

  @override
  void didPush() => onVisibilityChanged(true);

  @override
  void didPopNext() => onVisibilityChanged(true);

  @override
  void didPushNext() => onVisibilityChanged(false);

  @override
  void didPop() => onVisibilityChanged(false);
}

const Object _sentinel = Object();
