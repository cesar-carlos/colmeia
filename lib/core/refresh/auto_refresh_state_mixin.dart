import 'dart:async';

import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_persistence.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

mixin AutoRefreshStateMixin<T extends StatefulWidget> on State<T> {
  late final _AutoRefreshAppLifecycleObserver _autoRefreshAppLifecycleObserver;
  late final _AutoRefreshRouteAware _autoRefreshRouteAware;
  late final ValueNotifier<AutoRefreshUiState> _autoRefreshUiStateNotifier;
  Timer? _autoRefreshTimer;
  DateTime? _autoRefreshNextDueAt;
  Duration? _autoRefreshRemainingDelay;
  int _autoRefreshFailureStreak = 0;
  int _autoRefreshActiveReloads = 0;
  bool _autoRefreshAppVisible = true;
  bool _autoRefreshRouteVisible = true;
  bool _autoRefreshSupported = false;
  RouteObserver<ModalRoute<void>>? _autoRefreshSubscribedRouteObserver;
  bool _autoRefreshSnapshotRestored = false;

  ValueListenable<AutoRefreshUiState> get autoRefreshStateListenable =>
      _autoRefreshUiStateNotifier;

  AutoRefreshOption? get autoRefreshOption =>
      _autoRefreshUiStateNotifier.value.option;

  DateTime? get autoRefreshLastUpdatedAt =>
      _autoRefreshUiStateNotifier.value.lastUpdatedAt;

  @protected
  DateTime? get autoRefreshNextDueAt => _autoRefreshNextDueAt;

  @protected
  Duration? get autoRefreshRemainingDelay =>
      _resolveAutoRefreshRemainingDelay();

  @protected
  int get autoRefreshFailureStreak => _autoRefreshFailureStreak;

  @protected
  bool get autoRefreshIsBackingOff => _autoRefreshFailureStreak > 0;

  @protected
  bool get supportsAutoRefresh => true;

  @protected
  bool get canScheduleAutoRefresh => true;

  @protected
  bool get rebuildOnAutoRefreshStateChange => true;

  @protected
  AutoRefreshStatePersistence? get autoRefreshStatePersistence => null;

  @protected
  RouteObserver<ModalRoute<void>>? get autoRefreshRouteObserver => null;

  @protected
  Future<void> performAutoRefreshReload();

  @protected
  DateTime? resolveAutoRefreshCompletedAt() => DateTime.now();

  @protected
  DateTime get currentAutoRefreshTime => DateTime.now();

  @protected
  void didUpdateAutoRefreshState(AutoRefreshUiState state) {}

  @protected
  void logAutoRefreshInfo(String message, Map<String, Object?> context) {}

  @protected
  void logAutoRefreshWarning(String message, Map<String, Object?> context) {}

  @override
  void initState() {
    super.initState();
    _autoRefreshUiStateNotifier = ValueNotifier<AutoRefreshUiState>(
      const AutoRefreshUiState(),
    );
    _autoRefreshAppLifecycleObserver = _AutoRefreshAppLifecycleObserver(
      onVisibilityChanged: _setAutoRefreshAppVisibility,
    );
    _autoRefreshRouteAware = _AutoRefreshRouteAware(
      onVisibilityChanged: _setAutoRefreshRouteVisibility,
    );
    WidgetsBinding.instance.addObserver(_autoRefreshAppLifecycleObserver);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_autoRefreshSnapshotRestored) {
      _autoRefreshSnapshotRestored = true;
      final persistence = autoRefreshStatePersistence;
      if (persistence != null) {
        restoreAutoRefreshSnapshot(persistence.restoreAutoRefreshSnapshot());
      }
    }
    final supportsScheduling = supportsAutoRefresh;
    if (_autoRefreshSupported != supportsScheduling) {
      _autoRefreshSupported = supportsScheduling;
      _refreshAutoRefreshScheduling(resetDelayIfIdle: false);
    }
    if (_autoRefreshSubscribedRouteObserver != null) {
      return;
    }
    final routeObserver = autoRefreshRouteObserver;
    final route = ModalRoute.of(context);
    if (routeObserver != null && route is PageRoute<void>) {
      routeObserver.subscribe(_autoRefreshRouteAware, route);
      _autoRefreshSubscribedRouteObserver = routeObserver;
    }
  }

  @protected
  Future<void> reloadWithAutoRefresh({bool force = false}) async {
    if (!force && _autoRefreshActiveReloads > 0) {
      return;
    }
    _cancelAutoRefreshTimer();
    await _trackAutoRefreshReload(performAutoRefreshReload);
  }

  @protected
  void disableAutoRefresh() {
    _cancelAutoRefreshTimer();
    _autoRefreshNextDueAt = null;
    _autoRefreshRemainingDelay = null;
    _autoRefreshFailureStreak = 0;
    if (autoRefreshOption == null) {
      _publishAutoRefreshUiState();
      return;
    }
    _publishAutoRefreshUiState(option: null);
  }

  @protected
  void setAutoRefreshOption(AutoRefreshOption? option) {
    if (autoRefreshOption == option) {
      return;
    }
    _autoRefreshFailureStreak = 0;
    if (option == null) {
      _cancelAutoRefreshTimer();
      _autoRefreshRemainingDelay = null;
      _autoRefreshNextDueAt = null;
    } else {
      _setAutoRefreshNextCycle(
        delay: option.duration,
        anchorTime: currentAutoRefreshTime,
      );
    }
    _publishAutoRefreshUiState(option: option);
    _refreshAutoRefreshScheduling(resetDelayIfIdle: false);
  }

  @protected
  void restoreAutoRefreshSnapshot(
    AutoRefreshSnapshot snapshot, {
    bool notifyExternal = false,
    bool persistState = false,
  }) {
    final option = snapshot.option;
    _autoRefreshFailureStreak = snapshot.failureStreak;
    if (option == null) {
      _autoRefreshNextDueAt = null;
      _autoRefreshRemainingDelay = null;
    } else if (snapshot.remainingDelay != null) {
      _setAutoRefreshNextCycle(
        delay: snapshot.remainingDelay!,
        anchorTime: currentAutoRefreshTime,
      );
    } else if (snapshot.nextDueAt != null) {
      _autoRefreshNextDueAt = snapshot.nextDueAt;
      _autoRefreshRemainingDelay = _resolveAutoRefreshRemainingDelay();
    } else {
      final fallbackDelay = _resolveRestoredFallbackDelay(
        option: option,
        lastSuccessfulRefreshAt: snapshot.lastSuccessfulRefreshAt,
      );
      _setAutoRefreshNextCycle(
        delay: fallbackDelay,
        anchorTime: currentAutoRefreshTime,
      );
    }
    _publishAutoRefreshUiState(
      option: option,
      lastUpdatedAt: snapshot.lastSuccessfulRefreshAt,
      notifyExternal: notifyExternal,
      persistState: persistState,
    );
    _logAutoRefreshEvent(
      'Auto refresh restored',
      <String, Object?>{
        'optionId': option?.id,
        'lastSuccessfulRefreshAt': snapshot.lastSuccessfulRefreshAt
            ?.toIso8601String(),
        'nextDueAt': _autoRefreshNextDueAt?.toIso8601String(),
        'remainingMs': _resolveAutoRefreshRemainingDelay()?.inMilliseconds,
        'failureStreak': _autoRefreshFailureStreak,
      },
    );
    _refreshAutoRefreshScheduling(resetDelayIfIdle: false);
  }

  @protected
  void recordAutoRefreshSuccessfulReload(DateTime refreshedAt) {
    _autoRefreshFailureStreak = 0;
    final option = autoRefreshOption;
    if (option == null) {
      _autoRefreshNextDueAt = null;
      _autoRefreshRemainingDelay = null;
    } else {
      _setAutoRefreshNextCycle(
        delay: option.duration,
        anchorTime: currentAutoRefreshTime,
      );
    }
    _publishAutoRefreshUiState(lastUpdatedAt: refreshedAt);
    _logAutoRefreshEvent(
      'Auto refresh succeeded',
      <String, Object?>{
        'optionId': option?.id,
        'refreshedAt': refreshedAt.toIso8601String(),
        'nextDueAt': _autoRefreshNextDueAt?.toIso8601String(),
      },
    );
    _refreshAutoRefreshScheduling(resetDelayIfIdle: false);
  }

  @protected
  void refreshAutoRefreshScheduling({bool resetDelayIfIdle = false}) {
    _refreshAutoRefreshScheduling(resetDelayIfIdle: resetDelayIfIdle);
  }

  void _setAutoRefreshAppVisibility(bool visible) {
    if (_autoRefreshAppVisible == visible) {
      return;
    }
    _autoRefreshAppVisible = visible;
    _syncAutoRefreshTimerWithVisibility();
  }

  void _setAutoRefreshRouteVisibility(bool visible) {
    if (_autoRefreshRouteVisible == visible) {
      return;
    }
    _autoRefreshRouteVisible = visible;
    _syncAutoRefreshTimerWithVisibility();
  }

  void _syncAutoRefreshTimerWithVisibility() {
    _refreshAutoRefreshScheduling(resetDelayIfIdle: false);
  }

  Future<void> _handleAutoRefreshTick() async {
    _cancelAutoRefreshTimer();
    if (!mounted) {
      return;
    }
    if (!_canRunAutoRefreshTimer) {
      _refreshAutoRefreshScheduling(resetDelayIfIdle: false);
      return;
    }
    if (_autoRefreshActiveReloads > 0) {
      _logAutoRefreshEvent(
        'Auto refresh skipped while reload is active',
        <String, Object?>{
          'activeReloads': _autoRefreshActiveReloads,
          'optionId': autoRefreshOption?.id,
        },
      );
      return;
    }
    _logAutoRefreshEvent(
      'Auto refresh triggered',
      <String, Object?>{
        'optionId': autoRefreshOption?.id,
        'failureStreak': _autoRefreshFailureStreak,
      },
    );
    try {
      await _trackAutoRefreshReload(performAutoRefreshReload);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'auto refresh',
        ),
      );
    }
  }

  Future<void> _trackAutoRefreshReload(
    Future<void> Function() reload,
  ) async {
    _autoRefreshActiveReloads += 1;
    try {
      await reload();
      final completedAt = resolveAutoRefreshCompletedAt();
      if (completedAt != null) {
        recordAutoRefreshSuccessfulReload(completedAt);
      } else {
        _recordAutoRefreshFailure();
      }
    } on Object {
      _recordAutoRefreshFailure();
      rethrow;
    } finally {
      _autoRefreshActiveReloads -= 1;
      _refreshAutoRefreshScheduling(resetDelayIfIdle: false);
    }
  }

  bool get _canRunAutoRefreshTimer =>
      mounted &&
      _autoRefreshSupported &&
      _autoRefreshAppVisible &&
      _autoRefreshRouteVisible &&
      canScheduleAutoRefresh;

  void _refreshAutoRefreshScheduling({required bool resetDelayIfIdle}) {
    if (!_canRunAutoRefreshTimer) {
      _pauseAutoRefreshTimer();
      return;
    }
    final option = autoRefreshOption;
    if (option == null) {
      _cancelAutoRefreshTimer();
      _autoRefreshNextDueAt = null;
      _autoRefreshRemainingDelay = null;
      _publishAutoRefreshUiState(notifyExternal: false);
      return;
    }
    if (resetDelayIfIdle || _autoRefreshNextDueAt == null) {
      _setAutoRefreshNextCycle(
        delay: _resolveScheduledDelay(option),
        anchorTime: currentAutoRefreshTime,
      );
      _publishAutoRefreshUiState();
    }
    _scheduleAutoRefreshTimer();
  }

  void _scheduleAutoRefreshTimer() {
    _cancelAutoRefreshTimer();
    final nextDueAt = _autoRefreshNextDueAt;
    if (nextDueAt == null || !_canRunAutoRefreshTimer) {
      return;
    }
    final remainingDelay = nextDueAt.difference(currentAutoRefreshTime);
    if (remainingDelay <= Duration.zero) {
      scheduleMicrotask(() {
        if (!mounted) {
          return;
        }
        unawaited(_handleAutoRefreshTick());
      });
      return;
    }
    _autoRefreshRemainingDelay = remainingDelay;
    _autoRefreshTimer = Timer(remainingDelay, () {
      unawaited(_handleAutoRefreshTick());
    });
    _logAutoRefreshEvent(
      'Auto refresh scheduled',
      <String, Object?>{
        'optionId': autoRefreshOption?.id,
        'nextDueAt': nextDueAt.toIso8601String(),
        'remainingMs': remainingDelay.inMilliseconds,
        'failureStreak': _autoRefreshFailureStreak,
      },
    );
  }

  void _cancelAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void _pauseAutoRefreshTimer() {
    _cancelAutoRefreshTimer();
    _autoRefreshRemainingDelay = _resolveAutoRefreshRemainingDelay();
    _publishAutoRefreshUiState();
  }

  void _recordAutoRefreshFailure() {
    final option = autoRefreshOption;
    if (option == null) {
      _logAutoRefreshEvent('Auto refresh failed with scheduling disabled');
      return;
    }
    _autoRefreshFailureStreak += 1;
    final backoffDelay = _resolveBackoffDelay(
      option: option,
      failureStreak: _autoRefreshFailureStreak,
    );
    _setAutoRefreshNextCycle(
      delay: backoffDelay,
      anchorTime: currentAutoRefreshTime,
    );
    _publishAutoRefreshUiState();
    _logAutoRefreshEvent(
      'Auto refresh failed; backoff scheduled',
      <String, Object?>{
        'optionId': option.id,
        'failureStreak': _autoRefreshFailureStreak,
        'nextDueAt': _autoRefreshNextDueAt?.toIso8601String(),
        'remainingMs': _autoRefreshRemainingDelay?.inMilliseconds,
      },
      true,
    );
  }

  void _setAutoRefreshNextCycle({
    required Duration delay,
    required DateTime anchorTime,
  }) {
    final normalizedDelay = delay <= Duration.zero ? Duration.zero : delay;
    _autoRefreshRemainingDelay = normalizedDelay;
    _autoRefreshNextDueAt = anchorTime.add(normalizedDelay);
  }

  Duration _resolveScheduledDelay(AutoRefreshOption option) {
    if (_autoRefreshFailureStreak <= 0) {
      return option.duration;
    }
    return _resolveBackoffDelay(
      option: option,
      failureStreak: _autoRefreshFailureStreak,
    );
  }

  Duration _resolveBackoffDelay({
    required AutoRefreshOption option,
    required int failureStreak,
  }) {
    final multiplier = switch (failureStreak) {
      <= 0 => 1,
      1 => 2,
      2 => 4,
      _ => 8,
    };
    return option.duration * multiplier;
  }

  Duration _resolveRestoredFallbackDelay({
    required AutoRefreshOption option,
    required DateTime? lastSuccessfulRefreshAt,
  }) {
    if (lastSuccessfulRefreshAt == null) {
      return option.duration;
    }
    final dueAt = lastSuccessfulRefreshAt.add(option.duration);
    final remaining = dueAt.difference(currentAutoRefreshTime);
    return remaining <= Duration.zero ? Duration.zero : remaining;
  }

  Duration? _resolveAutoRefreshRemainingDelay() {
    final nextDueAt = _autoRefreshNextDueAt;
    if (nextDueAt == null) {
      return _autoRefreshRemainingDelay;
    }
    final remaining = nextDueAt.difference(currentAutoRefreshTime);
    return remaining <= Duration.zero ? Duration.zero : remaining;
  }

  void _publishAutoRefreshUiState({
    Object? option = _sentinel,
    Object? lastUpdatedAt = _sentinel,
    bool notifyExternal = true,
    bool persistState = true,
  }) {
    final current = _autoRefreshUiStateNotifier.value;
    final nextState = current.copyWith(
      option: identical(option, _sentinel)
          ? current.option
          : option as AutoRefreshOption?,
      lastUpdatedAt: identical(lastUpdatedAt, _sentinel)
          ? current.lastUpdatedAt
          : lastUpdatedAt as DateTime?,
      nextDueAt: _autoRefreshNextDueAt,
      remainingDelay: _resolveAutoRefreshRemainingDelay(),
      isBackingOff: _autoRefreshFailureStreak > 0,
      failureStreak: _autoRefreshFailureStreak,
    );
    _setAutoRefreshUiState(
      nextState,
      notifyExternal: notifyExternal,
      persistState: persistState,
    );
  }

  void _setAutoRefreshUiState(
    AutoRefreshUiState nextState, {
    bool notifyExternal = true,
    bool persistState = true,
  }) {
    final previousState = _autoRefreshUiStateNotifier.value;
    if (previousState.option == nextState.option &&
        previousState.lastUpdatedAt == nextState.lastUpdatedAt &&
        previousState.nextDueAt == nextState.nextDueAt &&
        previousState.remainingDelay == nextState.remainingDelay &&
        previousState.isBackingOff == nextState.isBackingOff &&
        previousState.failureStreak == nextState.failureStreak) {
      return;
    }
    _autoRefreshUiStateNotifier.value = nextState;
    if (notifyExternal) {
      didUpdateAutoRefreshState(nextState);
    }
    if (persistState) {
      final persistence = autoRefreshStatePersistence;
      if (persistence != null) {
        unawaited(
          persistence.persistAutoRefreshSnapshot(nextState.toSnapshot()),
        );
      }
    }
    if (rebuildOnAutoRefreshStateChange && mounted) {
      setState(() {});
    }
  }

  void _logAutoRefreshEvent(
    String message, [
    Map<String, Object?> context = const <String, Object?>{},
    bool warning = false,
  ]) {
    final payload = <String, Object?>{
      'owner': '$T',
      'optionId': autoRefreshOption?.id,
      ...context,
    };
    if (warning) {
      logAutoRefreshWarning(message, payload);
      return;
    }
    logAutoRefreshInfo(message, payload);
  }

  @override
  void dispose() {
    final routeObserver = _autoRefreshSubscribedRouteObserver;
    if (routeObserver != null) {
      routeObserver.unsubscribe(_autoRefreshRouteAware);
      _autoRefreshSubscribedRouteObserver = null;
    }
    WidgetsBinding.instance.removeObserver(_autoRefreshAppLifecycleObserver);
    _cancelAutoRefreshTimer();
    _autoRefreshUiStateNotifier.dispose();
    super.dispose();
  }
}

class _AutoRefreshAppLifecycleObserver extends WidgetsBindingObserver {
  _AutoRefreshAppLifecycleObserver({required this.onVisibilityChanged});

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

class _AutoRefreshRouteAware extends RouteAware {
  _AutoRefreshRouteAware({required this.onVisibilityChanged});

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
