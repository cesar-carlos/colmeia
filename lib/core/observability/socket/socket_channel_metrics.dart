import 'package:colmeia/core/observability/socket/socket_metrics_snapshot.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:flutter/foundation.dart';

/// In-memory metrics service for the consumer Socket channel. Designed to
/// be tiny and dependency-free so it can be the **first** observability
/// step (P0 in the performance review §5.8): without it, every later
/// optimization (jitter, coalescing, batch) becomes a guess.
///
/// Histograms keep a fixed-size reservoir of the **most recent** samples
/// and compute exact percentiles on the retained slice. For the volume the
/// app produces (a few thousand RPCs per session at most), this is
/// accurate enough; production analysis lives in the hub Prometheus.
///
/// Threading note: Dart is single-threaded per isolate, so no locking is
/// required as long as all method calls happen from the UI isolate.
class SocketChannelMetrics {
  SocketChannelMetrics({this.reservoirSize = 1024})
    : _handshakeMs = _ReservoirHistogram(reservoirSize),
      _dispatchMsByKey = <String, _ReservoirHistogram>{},
      _outcomesTotal = <String, int>{},
      _reconnectsByReason = <String, int>{},
      _batchSizeDistribution = _ReservoirHistogram(reservoirSize),
      _batchBypassByReason = <String, int>{},
      _relayPayloadDecodeWallClockMs = _ReservoirHistogram(reservoirSize),
      _relayAcceptToFirstChunkMs = _ReservoirHistogram(reservoirSize);

  /// Maximum number of samples kept per histogram. 1024 is the sweet spot
  /// for memory vs accuracy in client-side aggregation.
  final int reservoirSize;

  final _ReservoirHistogram _handshakeMs;
  final Map<String, _ReservoirHistogram> _dispatchMsByKey;
  final Map<String, int> _outcomesTotal;
  final Map<String, int> _reconnectsByReason;
  int _coalescedTotal = 0;
  int _batchEmissionsTotal = 0;
  int _batchPartialFailureTotal = 0;
  int _correlatorOrphanCompleteTotal = 0;
  int _correlatorOrphanFailTotal = 0;
  int _gateWaiterQueueRejectedTotal = 0;
  int _gateAcquireWaitTimeoutTotal = 0;
  int _relayStreamingUnhandledErrorTotal = 0;
  final _ReservoirHistogram _relayPayloadDecodeWallClockMs;
  final _ReservoirHistogram _relayAcceptToFirstChunkMs;
  int _relayGzipDecodeIsolateTotal = 0;
  int _relayJsonDecodeIsolateTotal = 0;
  final Map<String, int> _relayDecodeFailureByCode = <String, int>{};
  final _ReservoirHistogram _batchSizeDistribution;
  final Map<String, int> _batchBypassByReason;

  // ----- Recording API -----

  /// Records the duration of a fully-completed handshake (from
  /// `connect()` request to `connection:ready` decoded successfully).
  void recordHandshake({required Duration elapsed}) {
    _handshakeMs.add(elapsed.inMicroseconds / 1000.0);
  }

  /// Records the round-trip time of a single command dispatch. Pivot key
  /// is `"<agentId>|<method>"`. When [method] is null, falls back to
  /// `"<agentId>|<unknown>"` so all data lives under a single bucket.
  void recordDispatch({
    required String agentId,
    required String? method,
    required Duration elapsed,
  }) {
    final key = _dispatchKey(agentId: agentId, method: method);
    _dispatchMsByKey
        .putIfAbsent(key, () => _ReservoirHistogram(reservoirSize))
        .add(elapsed.inMicroseconds / 1000.0);
  }

  /// Records an outcome from `SocketCommandDispatcher.outcomes()`. Counts
  /// are per `(kind, reasonCode)` pair so PRs P1/P2 can compare ratios
  /// before/after activation.
  void recordOutcome({required AgentCommandOutcome outcome}) {
    final key = _outcomeKey(outcome);
    _outcomesTotal[key] = (_outcomesTotal[key] ?? 0) + 1;
  }

  /// Records a reconnect attempt by reason (e.g. `app_paused`,
  /// `transient_error`, `unauthorized`).
  void recordReconnect({required String reason}) {
    _reconnectsByReason[reason] = (_reconnectsByReason[reason] ?? 0) + 1;
  }

  /// Records that the dispatcher reused an in-flight Future instead of
  /// firing a new `agents:command` emit (PR-G coalescing).
  void recordCoalesced() {
    _coalescedTotal += 1;
  }

  /// Records that the batch coordinator emitted a batch with [size] items.
  /// Tracks both the counter and the size distribution histogram (PR-I).
  void recordBatchEmission({required int size, required bool partialFailure}) {
    _batchEmissionsTotal += 1;
    _batchSizeDistribution.add(size.toDouble());
    if (partialFailure) {
      _batchPartialFailureTotal += 1;
    }
  }

  /// Records that a submission bypassed the batch coordinator. Reasons:
  /// `paginated`, `multi_result`, `executeBatch`, `cancel`,
  /// `caller_opt_out`, `disabled`.
  void recordBatchBypass({required String reason}) {
    _batchBypassByReason[reason] = (_batchBypassByReason[reason] ?? 0) + 1;
  }

  /// Late wire response after the correlator dropped the pending entry
  /// ([operation] is `completeWith` or `failWith`).
  void recordCorrelatorOrphanWire({required String operation}) {
    if (operation == 'completeWith') {
      _correlatorOrphanCompleteTotal += 1;
    } else if (operation == 'failWith') {
      _correlatorOrphanFailTotal += 1;
    }
  }

  /// Waiter refused because the per-agent gate queue is at cap.
  void recordGateWaiterQueueRejected() {
    _gateWaiterQueueRejectedTotal += 1;
  }

  /// Queued gate acquire exceeded the configured max wait duration.
  void recordGateAcquireWaitTimeout() {
    _gateAcquireWaitTimeoutTotal += 1;
  }

  /// Unhandled async error in relay `sendStreaming` setup.
  void recordRelayStreamingUnhandledError() {
    _relayStreamingUnhandledErrorTotal += 1;
  }

  /// Wall time spent in `decodeJsonAsync` for one relay frame.
  void recordRelayPayloadDecodeWallClock({required Duration elapsed}) {
    _relayPayloadDecodeWallClockMs.add(elapsed.inMicroseconds / 1000.0);
  }

  /// Inbound gzip decoded via worker isolate for this frame.
  void recordRelayPayloadGzipDecodeIsolate() {
    _relayGzipDecodeIsolateTotal += 1;
  }

  /// JSON parse ran on a worker isolate for this frame.
  void recordRelayPayloadJsonDecodeIsolate() {
    _relayJsonDecodeIsolateTotal += 1;
  }

  /// Relay decode failure with stable `code` from `PayloadFrameCodec`.
  void recordRelayDecodeFailure({required String code}) {
    _relayDecodeFailureByCode[code] =
        (_relayDecodeFailureByCode[code] ?? 0) + 1;
  }

  /// Elapsed from successful stream accept to first chunk delivered.
  void recordRelayAcceptToFirstChunkWallClock({required Duration elapsed}) {
    _relayAcceptToFirstChunkMs.add(elapsed.inMicroseconds / 1000.0);
  }

  // ----- Inspection API -----

  /// Snapshot of all the current values. Cheap to compute; safe for the
  /// UI thread.
  SocketMetricsSnapshot snapshot() {
    return SocketMetricsSnapshot(
      handshakeMs: _handshakeMs.snapshot(),
      dispatchMsByKey: <String, HistogramSnapshot>{
        for (final entry in _dispatchMsByKey.entries)
          entry.key: entry.value.snapshot(),
      },
      outcomesTotal: Map<String, int>.unmodifiable(_outcomesTotal),
      reconnectsTotalByReason: Map<String, int>.unmodifiable(
        _reconnectsByReason,
      ),
      coalescedTotal: _coalescedTotal,
      batchEmissionsTotal: _batchEmissionsTotal,
      batchSizeDistribution: _batchSizeDistribution.snapshot(),
      batchPartialFailureTotal: _batchPartialFailureTotal,
      batchBypassTotalByReason: Map<String, int>.unmodifiable(
        _batchBypassByReason,
      ),
      correlatorOrphanCompleteTotal: _correlatorOrphanCompleteTotal,
      correlatorOrphanFailTotal: _correlatorOrphanFailTotal,
      gateWaiterQueueRejectedTotal: _gateWaiterQueueRejectedTotal,
      gateAcquireWaitTimeoutTotal: _gateAcquireWaitTimeoutTotal,
      relayStreamingUnhandledErrorTotal: _relayStreamingUnhandledErrorTotal,
      relayPayloadDecodeWallClockMs: _relayPayloadDecodeWallClockMs.snapshot(),
      relayAcceptToFirstChunkMs: _relayAcceptToFirstChunkMs.snapshot(),
      relayGzipDecodeIsolateTotal: _relayGzipDecodeIsolateTotal,
      relayJsonDecodeIsolateTotal: _relayJsonDecodeIsolateTotal,
      relayDecodeFailureTotalByCode: Map<String, int>.unmodifiable(
        _relayDecodeFailureByCode,
      ),
    );
  }

  /// Resets every counter and clears every reservoir. Used by tests and
  /// by the dev "clear metrics" action.
  @visibleForTesting
  void reset() {
    _handshakeMs.clear();
    _dispatchMsByKey.clear();
    _outcomesTotal.clear();
    _reconnectsByReason.clear();
    _coalescedTotal = 0;
    _batchEmissionsTotal = 0;
    _batchPartialFailureTotal = 0;
    _correlatorOrphanCompleteTotal = 0;
    _correlatorOrphanFailTotal = 0;
    _gateWaiterQueueRejectedTotal = 0;
    _gateAcquireWaitTimeoutTotal = 0;
    _relayStreamingUnhandledErrorTotal = 0;
    _relayGzipDecodeIsolateTotal = 0;
    _relayJsonDecodeIsolateTotal = 0;
    _relayDecodeFailureByCode.clear();
    _relayPayloadDecodeWallClockMs.clear();
    _relayAcceptToFirstChunkMs.clear();
    _batchSizeDistribution.clear();
    _batchBypassByReason.clear();
  }

  // ----- Helpers -----

  String _dispatchKey({required String agentId, required String? method}) {
    return '$agentId|${method ?? '<unknown>'}';
  }

  String _outcomeKey(AgentCommandOutcome outcome) {
    final kind = outcome.runtimeType.toString();
    final reason = switch (outcome) {
      AgentCommandSuccess() => '-',
      AgentCommandFailedOffline(:final reasonCode) => reasonCode,
      AgentCommandFailedAuth(:final reasonCode) => reasonCode,
      AgentCommandFailedTransient(:final reasonCode) => reasonCode,
    };
    return '$kind|$reason';
  }
}

/// Bounded-size reservoir histogram. Newer samples evict older ones.
/// Percentiles are computed on demand via insertion sort over the
/// retained samples.
class _ReservoirHistogram {
  _ReservoirHistogram(this._capacity)
    : _samples = List<double>.filled(_capacity, 0);

  final int _capacity;
  final List<double> _samples;
  int _size = 0;
  int _writeIndex = 0;
  int _totalCount = 0;
  double _max = 0;

  void add(double sample) {
    _samples[_writeIndex] = sample;
    _writeIndex = (_writeIndex + 1) % _capacity;
    if (_size < _capacity) {
      _size += 1;
    }
    _totalCount += 1;
    if (sample > _max) {
      _max = sample;
    }
  }

  void clear() {
    _size = 0;
    _writeIndex = 0;
    _totalCount = 0;
    _max = 0;
  }

  HistogramSnapshot snapshot() {
    if (_size == 0) {
      return HistogramSnapshot.empty;
    }
    final retained = List<double>.generate(
      _size,
      (i) => _samples[i],
      growable: false,
    )..sort();
    final mean = retained.reduce((a, b) => a + b) / retained.length;
    return HistogramSnapshot(
      count: _totalCount,
      mean: mean,
      p50: _percentile(retained, 0.50),
      p95: _percentile(retained, 0.95),
      p99: _percentile(retained, 0.99),
      max: _max,
    );
  }

  double _percentile(List<double> sorted, double percentile) {
    if (sorted.isEmpty) {
      return 0;
    }
    if (sorted.length == 1) {
      return sorted.first;
    }
    final rank = (percentile * (sorted.length - 1)).clamp(
      0,
      sorted.length - 1,
    );
    final lower = rank.floor();
    final upper = rank.ceil();
    if (lower == upper) {
      return sorted[lower];
    }
    final fraction = rank - lower;
    return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction;
  }
}
