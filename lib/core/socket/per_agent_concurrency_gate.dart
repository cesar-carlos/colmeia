import 'dart:async';
import 'dart:collection';

/// Bounds the number of in-flight `agents:command` dispatches per agent.
///
/// Mirror of the hub's `SOCKET_REST_AGENT_MAX_INFLIGHT` (default 32) but
/// **conservative on purpose** (default 8 in the app). Without this gate
/// the `AgentQueryExecutor` may issue 16 parallel queries to the same
/// agent and burst the hub rate limit (review §5.5, P1).
///
/// Acquire/release semantics:
///
/// - `acquire(agentId)` returns immediately when the per-agent counter is
///   below [maxInflightPerAgent]; otherwise the future completes when an
///   earlier `release(agentId)` frees a slot.
/// - `release(agentId)` MUST be called exactly once for every `acquire`
///   that completed (typically inside `finally`).
/// - The waiter queue is unbounded unless [maxWaitersPerAgent] is set;
///   callers should pair the gate with a request timeout to avoid
///   head-of-line blocking forever (`SocketCommandDispatcher` already does
///   that via the correlator).
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

  /// Currently consumed slots for [agentId]. Useful for metrics.
  int inflightFor(String agentId) => _inflight[agentId] ?? 0;

  /// Returns the highest [inflightFor] value across every agent (peak
  /// concurrency observed by the gate). Useful for diagnosis.
  int get peakInflight {
    var peak = 0;
    for (final value in _inflight.values) {
      if (value > peak) {
        peak = value;
      }
    }
    return peak;
  }

  /// Number of waiters currently blocked on [agentId].
  int waitingFor(String agentId) => _waiters[agentId]?.length ?? 0;

  Future<void> acquire(String agentId) async {
    final current = _inflight[agentId] ?? 0;
    if (current < maxInflightPerAgent) {
      _inflight[agentId] = current + 1;
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
              'agentId=$agentId',
              waitBudget,
            ),
          );
        }
      });
    }
    queue.add(_QueuedWaiter(completer: completer, timeoutTimer: timer));
    try {
      await completer.future;
    } finally {
      timer?.cancel();
    }
  }

  void release(String agentId) {
    final waiters = _waiters[agentId];
    if (waiters != null && waiters.isNotEmpty) {
      while (waiters.isNotEmpty) {
        final next = waiters.removeFirst();
        final completer = next.completer;
        next.cancelTimer();
        if (completer.isCompleted) {
          continue;
        }
        completer.complete();
        if (waiters.isEmpty) {
          _waiters.remove(agentId);
        }
        return;
      }
      _waiters.remove(agentId);
    }
    final current = _inflight[agentId] ?? 0;
    if (current <= 1) {
      _inflight.remove(agentId);
    } else {
      _inflight[agentId] = current - 1;
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
  _QueuedWaiter({required this.completer, this.timeoutTimer});

  final Completer<void> completer;
  final Timer? timeoutTimer;

  void cancelTimer() => timeoutTimer?.cancel();
}
