import 'dart:async';

import 'package:flutter/foundation.dart';

/// Reusable gate that throttles a UI action after the server signals a
/// `Retry-After` (HTTP header / `error.data.retry_after_ms` / `reset_at`).
///
/// Usage from a controller:
///
/// ```dart
/// final retryGate = RetryAfterGate();
/// // wire `retryGate` as a child notifier:
/// retryGate.addListener(notifyListeners);
///
/// Future<void> sync() async {
///   if (!retryGate.isOpen) return;
///   final result = await syncUseCase();
///   final failure = result.exceptionOrNull();
///   if (failure is NetworkFailure && failure.retryAfter != null) {
///     retryGate.arm(failure.retryAfter!);
///   }
/// }
/// ```
///
/// The gate exposes itself as a [ChangeNotifier] so widgets can react to
/// the countdown without subscribing to a separate `Stream`. The internal
/// [Timer] is cancelled on [dispose] and on every new [arm] / [release]
/// to keep the pump count predictable in tests.
///
/// ## App-wide singleton vs route-scoped controllers
///
/// A single [RetryAfterGate] may be registered in GetIt and shared with
/// prefetch coordinators (for example overview fact backfill). Route-scoped
/// controllers that receive an injected gate must **not** call [dispose] on
/// it — only [removeListener] for subscriptions they added. Controllers that
/// construct their own gate (`retryAfterGate ?? RetryAfterGate()`) should
/// dispose it when they own the instance. See `OverviewController` for the
/// ownership flag pattern.
class RetryAfterGate extends ChangeNotifier {
  RetryAfterGate({
    Duration tickInterval = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : _tickInterval = tickInterval,
       _clock = clock ?? DateTime.now;

  /// Granularity of countdown updates surfaced via [notifyListeners]. The
  /// default is 1s — enough to drive a "Retry in 12s" label without
  /// thrashing rebuilds. Tests inject a smaller value to keep the suite
  /// fast.
  final Duration _tickInterval;

  /// Indirection over [DateTime.now] so tests can drive the clock with
  /// `FakeAsync`.
  final DateTime Function() _clock;

  DateTime? _openAt;
  Timer? _ticker;
  bool _disposed = false;

  /// `true` when the action is allowed (no cooldown, or cooldown expired).
  bool get isOpen => remaining == null;

  /// Time left in the cooldown window. `null` when the gate is open. The
  /// value is rounded down to whole seconds so the UI does not jitter on
  /// sub-second drift between the local clock and the server's
  /// `Retry-After` reference.
  Duration? get remaining {
    final until = _openAt;
    if (until == null) {
      return null;
    }
    final delta = until.difference(_clock());
    if (delta.isNegative || delta == Duration.zero) {
      return null;
    }
    return Duration(
      seconds: delta.inSeconds + (delta.inMilliseconds % 1000 > 0 ? 1 : 0),
    );
  }

  /// Opens the cooldown window for [retryAfter] starting now. Reuses the
  /// **largest** wait when called repeatedly so a slow second response
  /// does not shrink an already-armed gate.
  ///
  /// Passing a non-positive [retryAfter] releases the gate immediately
  /// (defensive — some servers report `retry_after_ms: 0` as "you can
  /// retry now").
  void arm(Duration retryAfter) {
    if (_disposed) {
      return;
    }
    if (retryAfter <= Duration.zero) {
      release();
      return;
    }
    final candidate = _clock().add(retryAfter);
    final current = _openAt;
    final next = current == null || candidate.isAfter(current)
        ? candidate
        : current;
    if (current == next) {
      return;
    }
    _openAt = next;
    _restartTicker();
    notifyListeners();
  }

  /// Cancels any active cooldown and notifies listeners.
  void release() {
    if (_disposed) {
      return;
    }
    if (_openAt == null) {
      return;
    }
    _openAt = null;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void _restartTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (_) {
      if (_disposed) {
        return;
      }
      if (remaining == null) {
        _openAt = null;
        _ticker?.cancel();
        _ticker = null;
        notifyListeners();
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _ticker = null;
    _openAt = null;
    super.dispose();
  }
}
