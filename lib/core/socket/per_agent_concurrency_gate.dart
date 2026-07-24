import 'dart:async';
import 'dart:collection';

/// Thrown when a queued [PerAgentConcurrencyGate.acquire] wait is cancelled
/// (e.g. `RelayCommandDispatcher.cancel`) before a slot is granted.
final class GateQueueWaitCancelled implements Exception {
  const GateQueueWaitCancelled();
}

/// Bounds the number of in-flight `agents:command` / relay dispatches per
/// agent.
///
/// Mirror of the hub's `SOCKET_REST_AGENT_MAX_INFLIGHT` (default 32) but
/// **conservative on purpose** (default 8 in the app). Without this gate
/// the `AgentQueryExecutor` may issue 16 parallel queries to the same
/// agent and burst the hub rate limit (review §5.5, P1).
///
/// Acquire/release semantics:
///
/// - [acquire] / [acquireSlots] return immediately when the per-agent
///   counter has enough free capacity; otherwise the future completes when
///   earlier [release] / [releaseSlots] frees room.
/// - [release] / [releaseSlots] MUST be called for every acquire that
///   completed (typically inside `finally`), with matching slot counts.
/// - [acquireSlots] is atomic: either all requested slots are granted together
///   or the caller waits until they all fit. This prevents relay batch
///   deadlocks that arise from acquiring one slot per item in a loop.
/// - The waiter queue is unbounded unless [maxWaitersPerAgent] is set.
/// - When [maxWaitForSlot] is set, a waiter that stays queued longer than
///   that duration completes with [TimeoutException] and is removed from
///   the queue (no slot is consumed).
class PerAgentConcurrencyGate {
  PerAgentConcurrencyGate({
    this.maxInflightPerAgent = 8,
    this.maxWaitersPerAgent,
    this.maxWaitForSlot,
    this.onWaiterQueueRejected,
    this.onAcquireWaitTimeout,
  }) : assert(
         maxInflightPerAgent > 0,
         'maxInflightPerAgent must be greater than zero',
       ),
       assert(
         maxWaitersPerAgent == null || maxWaitersPerAgent >= 0,
         'maxWaitersPerAgent must be null or non-negative',
       );

  /// Per-agent ceiling. Default 8 is half of the hub's REST default to
  /// leave headroom for the relay channel and for other consumers sharing
  /// the same JWT.
  final int maxInflightPerAgent;

  /// Maximum queued waiters per agent id when in-flight work is at
  /// [maxInflightPerAgent]. `null` means no limit (legacy behaviour).
  final int? maxWaitersPerAgent;

  /// Maximum time a caller may wait in the per-agent queue for a slot.
  /// `null` means no limit (legacy behaviour).
  final Duration? maxWaitForSlot;

  /// Optional hook when [acquire] refuses a new waiter because the queue
  /// is at [maxWaitersPerAgent].
  final void Function()? onWaiterQueueRejected;

  /// Optional hook when a queued [acquire] hits [maxWaitForSlot].
  final void Function()? onAcquireWaitTimeout;

  final Map<String, int> _inflight = <String, int>{};
  final Map<String, Queue<_QueuedWaiter>> _waiters =
      <String, Queue<_QueuedWaiter>>{};

  /// Session maximum of per-agent in-flight slots observed since process
  /// start (or last [resetSessionConcurrencyPeak]). Updated in O(1) on
  /// each direct acquire by comparing the new per-agent count against the
  /// running maximum — no full scan of `_inflight.values` required.
  int _sessionPeakMaxAgentInflight = 0;

  /// Currently consumed slots for [agentId]. Useful for metrics.
  int inflightFor(String agentId) => _inflight[agentId] ?? 0;

  /// Returns the highest [inflightFor] value across every agent at the
  /// current instant. O(n) in the number of tracked agents; intended for
  /// diagnostic snapshots, not for the hot-path. Prefer
  /// [sessionPeakMaxAgentInflight] for ongoing monitoring.
  int get peakInflight {
    var peak = 0;
    for (final value in _inflight.values) {
      if (value > peak) {
        peak = value;
      }
    }
    return peak;
  }

  /// Session maximum of [peakInflight] (max concurrent slots for any single
  /// agent at a point in time). Resets when [resetSessionConcurrencyPeak]
  /// is called (typically after exporting metrics on disconnect).
  int get sessionPeakMaxAgentInflight => _sessionPeakMaxAgentInflight;

  /// O(1): called only when a slot is directly granted (not when a waiter
  /// merely inherits a released slot — the per-agent count stays the same
  /// in that case). The session peak is monotonically non-decreasing, so
  /// release paths never need to update it.
  void _updateSessionPeak(int newCount) {
    if (newCount > _sessionPeakMaxAgentInflight) {
      _sessionPeakMaxAgentInflight = newCount;
    }
  }

  /// Clears the session peak gauge after it has been sampled for export.
  void resetSessionConcurrencyPeak() {
    _sessionPeakMaxAgentInflight = 0;
  }

  /// Number of waiters currently blocked on [agentId].
  int waitingFor(String agentId) => _waiters[agentId]?.length ?? 0;

  /// Removes a queued [acquire] waiter without granting a slot. Used when
  /// the owning request is cancelled before [acquire] completes.
  void cancelQueuedWaiter(String agentId, Completer<void> waiter) {
    _removeQueuedWaiter(agentId, waiter);
    if (!waiter.isCompleted) {
      waiter.completeError(const GateQueueWaitCancelled());
    }
  }

  /// Acquires a single slot. Equivalent to [acquireSlots] with `count: 1`.
  Future<void> acquire(
    String agentId, {
    void Function(Completer<void> queuedWaitCompleter)? onQueuedWaiter,
  }) => acquireSlots(agentId, 1, onQueuedWaiter: onQueuedWaiter);

  /// Atomically reserves [count] slots for [agentId].
  ///
  /// Throws [ArgumentError] when [count] is less than 1. Throws [StateError]
  /// when [count] exceeds [maxInflightPerAgent] (the request can never be
  /// satisfied) or when the waiter queue is at [maxWaitersPerAgent].
  Future<void> acquireSlots(
    String agentId,
    int count, {
    void Function(Completer<void> queuedWaitCompleter)? onQueuedWaiter,
  }) async {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'must be >= 1');
    }
    if (count > maxInflightPerAgent) {
      throw StateError(
        'PerAgentConcurrencyGate cannot grant $count slots for '
        'agentId=$agentId (maxInflightPerAgent=$maxInflightPerAgent)',
      );
    }
    final current = _inflight[agentId] ?? 0;
    final hasWaiters = _waiters[agentId]?.isNotEmpty ?? false;
    // Strict FIFO: once anyone is queued, later callers join the queue
    // even if their smaller count would fit in free capacity. Otherwise a
    // multi-slot batch waiter can be starved forever by unary acquires.
    if (!hasWaiters && current + count <= maxInflightPerAgent) {
      final newCount = current + count;
      _inflight[agentId] = newCount;
      _updateSessionPeak(newCount);
      return;
    }
    final queue = _waiters.putIfAbsent(agentId, Queue<_QueuedWaiter>.new);
    final cap = maxWaitersPerAgent;
    if (cap != null && queue.length >= cap) {
      onWaiterQueueRejected?.call();
      throw StateError(
        'PerAgentConcurrencyGate waiter queue exceeded for agentId=$agentId '
        '(maxWaitersPerAgent=$cap)',
      );
    }
    final completer = Completer<void>();
    final waitBudget = maxWaitForSlot;
    Timer? timer;
    if (waitBudget != null) {
      timer = Timer(waitBudget, () {
        _removeQueuedWaiter(agentId, completer);
        if (!completer.isCompleted) {
          onAcquireWaitTimeout?.call();
          completer.completeError(
            TimeoutException(
              'PerAgentConcurrencyGate acquire wait exceeded for '
              'agentId=$agentId (slots=$count)',
              waitBudget,
            ),
          );
        }
      });
    }
    queue.add(
      _QueuedWaiter(
        completer: completer,
        timeoutTimer: timer,
        slotCount: count,
      ),
    );
    onQueuedWaiter?.call(completer);
    try {
      await completer.future;
    } finally {
      timer?.cancel();
    }
  }

  /// Releases a single slot. Equivalent to [releaseSlots] with `count: 1`.
  void release(String agentId) => releaseSlots(agentId, 1);

  /// Releases [count] previously acquired slots for [agentId], then tries
  /// to grant the next FIFO waiter(s) that fit in the freed capacity.
  void releaseSlots(String agentId, int count) {
    if (count < 1) {
      return;
    }
    final current = _inflight[agentId] ?? 0;
    final remaining = current - count;
    if (remaining <= 0) {
      _inflight.remove(agentId);
    } else {
      _inflight[agentId] = remaining;
    }
    _grantReadyWaiters(agentId);
  }

  /// FIFO grant: wake the head waiter only when its full slot count fits.
  /// Never skip over a larger head waiter to serve a smaller one — that
  /// would starve multi-slot batch acquires.
  void _grantReadyWaiters(String agentId) {
    final waiters = _waiters[agentId];
    if (waiters == null || waiters.isEmpty) {
      return;
    }
    while (waiters.isNotEmpty) {
      final next = waiters.first;
      final current = _inflight[agentId] ?? 0;
      if (current + next.slotCount > maxInflightPerAgent) {
        break;
      }
      waiters.removeFirst();
      next.cancelTimer();
      final newCount = current + next.slotCount;
      _inflight[agentId] = newCount;
      _updateSessionPeak(newCount);
      if (!next.completer.isCompleted) {
        next.completer.complete();
      }
    }
    if (waiters.isEmpty) {
      _waiters.remove(agentId);
    }
  }

  void _removeQueuedWaiter(String agentId, Completer<void> target) {
    final q = _waiters[agentId];
    if (q == null) {
      return;
    }
    final retained = Queue<_QueuedWaiter>();
    while (q.isNotEmpty) {
      final w = q.removeFirst();
      if (identical(w.completer, target)) {
        w.cancelTimer();
      } else {
        retained.add(w);
      }
    }
    if (retained.isEmpty) {
      _waiters.remove(agentId);
    } else {
      _waiters[agentId] = retained;
    }
  }
}

class _QueuedWaiter {
  _QueuedWaiter({
    required this.completer,
    this.timeoutTimer,
    this.slotCount = 1,
  });

  final Completer<void> completer;
  final Timer? timeoutTimer;
  final int slotCount;

  void cancelTimer() => timeoutTimer?.cancel();
}
