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
/// - The gate is process-wide and unbounded in queue size; callers should
///   pair it with a request timeout to avoid head-of-line blocking forever
///   (`SocketCommandDispatcher` already does that via the correlator).
class PerAgentConcurrencyGate {
  PerAgentConcurrencyGate({this.maxInflightPerAgent = 8})
    : assert(
        maxInflightPerAgent > 0,
        'maxInflightPerAgent must be greater than zero',
      );

  /// Per-agent ceiling. Default 8 is half of the hub's REST default to
  /// leave headroom for the relay channel and for other consumers sharing
  /// the same JWT.
  final int maxInflightPerAgent;

  final Map<String, int> _inflight = <String, int>{};
  final Map<String, Queue<Completer<void>>> _waiters =
      <String, Queue<Completer<void>>>{};

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

  Future<void> acquire(String agentId) {
    final current = _inflight[agentId] ?? 0;
    if (current < maxInflightPerAgent) {
      _inflight[agentId] = current + 1;
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _waiters.putIfAbsent(agentId, Queue<Completer<void>>.new).add(completer);
    return completer.future;
  }

  void release(String agentId) {
    final waiters = _waiters[agentId];
    if (waiters != null && waiters.isNotEmpty) {
      // Hand the slot directly to the next waiter; counter stays the same.
      final next = waiters.removeFirst();
      if (waiters.isEmpty) {
        _waiters.remove(agentId);
      }
      if (!next.isCompleted) {
        next.complete();
        return;
      }
      // The waiter was cancelled before being served; fall through and
      // properly decrement the counter so we do not leak a slot.
    }
    final current = _inflight[agentId] ?? 0;
    if (current <= 1) {
      _inflight.remove(agentId);
    } else {
      _inflight[agentId] = current - 1;
    }
  }
}
