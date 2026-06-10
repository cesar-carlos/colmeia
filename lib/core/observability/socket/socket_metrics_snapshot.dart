import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart'
    show PerAgentConcurrencyGate;

/// Read-only snapshot of `SocketChannelMetrics`. Useful for diagnostics,
/// snapshot tests, manual inspection in debug builds, and compact relay
/// slices via [relayDebugLogFields].
class SocketMetricsSnapshot {
  const SocketMetricsSnapshot({
    required this.handshakeMs,
    required this.dispatchMsByKey,
    required this.outcomesTotal,
    required this.reconnectsTotalByReason,
    required this.coalescedTotal,
    required this.batchEmissionsTotal,
    required this.batchSizeDistribution,
    required this.batchPartialFailureTotal,
    required this.batchBypassTotalByReason,
    this.correlatorOrphanCompleteTotal = 0,
    this.correlatorOrphanFailTotal = 0,
    this.gateWaiterQueueRejectedTotal = 0,
    this.gateAcquireWaitTimeoutTotal = 0,
    this.relayStreamingUnhandledErrorTotal = 0,
    this.relayPayloadDecodeWallClockMs = HistogramSnapshot.empty,
    this.relayPayloadEncodeWallClockMs = HistogramSnapshot.empty,
    this.relayAcceptToFirstChunkMs = HistogramSnapshot.empty,
    this.relayRequestToAcceptedMs = HistogramSnapshot.empty,
    this.relayAcceptedToResponseMs = HistogramSnapshot.empty,
    this.relayConversationStartMs = HistogramSnapshot.empty,
    this.relayGzipDecodeIsolateTotal = 0,
    this.relayJsonDecodeIsolateTotal = 0,
    this.relayDecodeFailureTotalByCode = const <String, int>{},
    this.relayDispatchMsByKey = const <String, HistogramSnapshot>{},
    this.relayOutcomesTotal = const <String, int>{},
    this.relayBatchEmissionsTotal = 0,
    this.relayBatchSizeDistribution = HistogramSnapshot.empty,
    this.relayBatchPartialFailureTotal = 0,
    this.relayBatchBypassTotalByReason = const <String, int>{},
    this.serverPhaseMsByName = const <String, HistogramSnapshot>{},
    this.serverTimingsSchemaMismatchTotal = 0,
    this.restFallbackLatchTotal = 0,
    this.lastGateSessionPeakSample = 0,
  });

  /// Histogram across **all** completed handshakes since process start
  /// (or last `reset()`).
  final HistogramSnapshot handshakeMs;

  /// Per-key histograms of `dispatch_ms`. The key format is
  /// `"<agentId>|<method>"` (or `"<agentId>|<unknown>"` when the method
  /// could not be extracted).
  final Map<String, HistogramSnapshot> dispatchMsByKey;

  /// Counter map keyed by `"<kind>|<reasonCode>"` (e.g.
  /// `"AgentCommandSuccess|-"`, `"AgentCommandFailedAuth|AGENT_ACCESS_DENIED"`).
  final Map<String, int> outcomesTotal;

  /// Counter map keyed by reconnect reason (e.g. `app_paused`,
  /// `unauthorized`, `transient_error`).
  final Map<String, int> reconnectsTotalByReason;

  /// Number of `agents:command` calls that were deduplicated against an
  /// in-flight request (PR-G coalescing). Higher is better.
  final int coalescedTotal;

  /// PR-I: total batches emitted (each one wraps 1..N RPCs).
  final int batchEmissionsTotal;

  /// PR-I: histogram of items per batch (count + percentiles).
  final HistogramSnapshot batchSizeDistribution;

  /// PR-I: number of batches where at least one item came back with an
  /// RPC-level error.
  final int batchPartialFailureTotal;

  /// PR-I: counts of submissions that bypassed the batch coordinator
  /// (`paginated`, `multi_result`, `executeBatch`, `cancel`,
  /// `caller_opt_out`, `disabled`).
  final Map<String, int> batchBypassTotalByReason;

  /// `completeWith` calls that arrived after the pending entry was gone.
  final int correlatorOrphanCompleteTotal;

  /// `failWith` calls that arrived after the pending entry was gone.
  final int correlatorOrphanFailTotal;

  /// Per-agent gate refused a waiter because the queue was full.
  final int gateWaiterQueueRejectedTotal;

  /// Queued gate acquire timed out before a slot was granted.
  final int gateAcquireWaitTimeoutTotal;

  /// Relay `sendStreaming` async error surfaced via the error handler.
  final int relayStreamingUnhandledErrorTotal;

  /// Wall-clock time for `PayloadFrameCodec.decodeJsonAsync` on relay
  /// `rpc.response` / `rpc.chunk` / `rpc.complete` (ms, reservoir).
  final HistogramSnapshot relayPayloadDecodeWallClockMs;

  /// Wall-clock time for `PayloadFrameCodec.encodeJsonAsync` on relay
  /// `rpc.request` (ms, reservoir). Pairs with the decode counterpart
  /// to surface the JSON/PayloadFrame share of relay latency.
  final HistogramSnapshot relayPayloadEncodeWallClockMs;

  /// Time from successful `relay:rpc.accepted` to first delivered chunk
  /// on streaming RPCs (ms, reservoir).
  final HistogramSnapshot relayAcceptToFirstChunkMs;

  /// Time from `relay:rpc.request` emit to `relay:rpc.accepted` (ms,
  /// reservoir). Diagnoses the consumer→hub leg plus hub-side
  /// validation/enqueue cost on both unary and streaming RPCs.
  final HistogramSnapshot relayRequestToAcceptedMs;

  /// Time from `relay:rpc.accepted` to `relay:rpc.response` on unary
  /// RPCs (ms, reservoir). Diagnoses the agent forward + SQL execute
  /// + reply path; streaming RPCs are covered by
  /// [relayAcceptToFirstChunkMs] instead.
  final HistogramSnapshot relayAcceptedToResponseMs;

  /// One `relay:conversation.start → relay:conversation.started`
  /// round-trip per first-time `obtain(agentId)` call (ms, reservoir).
  /// Exposes the cost the pre-warmer is meant to hide.
  final HistogramSnapshot relayConversationStartMs;

  /// Inbound gzip frames decoded via a worker isolate.
  final int relayGzipDecodeIsolateTotal;

  /// Frames whose JSON parse ran on a worker isolate.
  final int relayJsonDecodeIsolateTotal;

  /// Counts of decode failures by stable `code` (e.g. `gzip_decode_failed`).
  final Map<String, int> relayDecodeFailureTotalByCode;

  /// Relay unary/streaming dispatch latency by `"<agentId>|<method>"`.
  final Map<String, HistogramSnapshot> relayDispatchMsByKey;

  /// Relay outcome counts keyed like legacy outcomes
  /// (`RelayRpcSuccess|-`, `RelayRpcFailure|<code>`).
  final Map<String, int> relayOutcomesTotal;

  /// Hub item 1: total `relay:rpc.request.batch` envelopes the relay
  /// coordinator flushed (each wraps 1..32 RPCs).
  final int relayBatchEmissionsTotal;

  /// Hub item 1: histogram of items per relay batch envelope.
  final HistogramSnapshot relayBatchSizeDistribution;

  /// Hub item 1: number of relay batches with at least one item that
  /// completed with an error.
  final int relayBatchPartialFailureTotal;

  /// Hub item 1: counts of relay `sendUnary` calls the coordinator
  /// bypassed because they were ineligible for batch (`prefer_db_streaming`,
  /// `multi_result`, `executeBatch`, `cancel`, `unknown_method`).
  final Map<String, int> relayBatchBypassTotalByReason;

  /// Per-phase histograms reported by the hub via `meta.serverTimings`
  /// (relay) or `serverTimings` (`agents:command` / REST). Key is the
  /// phase name (`encode_ms`, `agent_to_hub_ms`, etc.). Empty when no
  /// request opted into `requestServerTimings: true`.
  final Map<String, HistogramSnapshot> serverPhaseMsByName;

  /// Number of `serverTimings` payloads observed with a `schemaVersion`
  /// the client does not understand. Non-zero in this counter means a
  /// hub bump rolled out — bump the client schema handling.
  final int serverTimingsSchemaMismatchTotal;

  /// Times the SQL datasource latched to REST for auth/namespace failures.
  final int restFallbackLatchTotal;

  /// Last sampled [PerAgentConcurrencyGate.sessionPeakMaxAgentInflight] at
  /// socket disconnect export (0 if never sampled).
  final int lastGateSessionPeakSample;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'handshakeMs': handshakeMs.toJson(),
      'dispatchMsByKey': <String, Object?>{
        for (final entry in dispatchMsByKey.entries)
          entry.key: entry.value.toJson(),
      },
      'outcomesTotal': outcomesTotal,
      'reconnectsTotalByReason': reconnectsTotalByReason,
      'coalescedTotal': coalescedTotal,
      'batchEmissionsTotal': batchEmissionsTotal,
      'batchSizeDistribution': batchSizeDistribution.toJson(),
      'batchPartialFailureTotal': batchPartialFailureTotal,
      'batchBypassTotalByReason': batchBypassTotalByReason,
      'correlatorOrphanCompleteTotal': correlatorOrphanCompleteTotal,
      'correlatorOrphanFailTotal': correlatorOrphanFailTotal,
      'gateWaiterQueueRejectedTotal': gateWaiterQueueRejectedTotal,
      'gateAcquireWaitTimeoutTotal': gateAcquireWaitTimeoutTotal,
      'relayStreamingUnhandledErrorTotal': relayStreamingUnhandledErrorTotal,
      'relayPayloadDecodeWallClockMs': relayPayloadDecodeWallClockMs.toJson(),
      'relayPayloadEncodeWallClockMs': relayPayloadEncodeWallClockMs.toJson(),
      'relayAcceptToFirstChunkMs': relayAcceptToFirstChunkMs.toJson(),
      'relayRequestToAcceptedMs': relayRequestToAcceptedMs.toJson(),
      'relayAcceptedToResponseMs': relayAcceptedToResponseMs.toJson(),
      'relayConversationStartMs': relayConversationStartMs.toJson(),
      'relayGzipDecodeIsolateTotal': relayGzipDecodeIsolateTotal,
      'relayJsonDecodeIsolateTotal': relayJsonDecodeIsolateTotal,
      'relayDecodeFailureTotalByCode': relayDecodeFailureTotalByCode,
      'relayDispatchMsByKey': <String, Object?>{
        for (final entry in relayDispatchMsByKey.entries)
          entry.key: entry.value.toJson(),
      },
      'relayOutcomesTotal': relayOutcomesTotal,
      'relayBatchEmissionsTotal': relayBatchEmissionsTotal,
      'relayBatchSizeDistribution': relayBatchSizeDistribution.toJson(),
      'relayBatchPartialFailureTotal': relayBatchPartialFailureTotal,
      'relayBatchBypassTotalByReason': relayBatchBypassTotalByReason,
      'serverPhaseMsByName': <String, Object?>{
        for (final entry in serverPhaseMsByName.entries)
          entry.key: entry.value.toJson(),
      },
      'serverTimingsSchemaMismatchTotal': serverTimingsSchemaMismatchTotal,
      'restFallbackLatchTotal': restFallbackLatchTotal,
      'lastGateSessionPeakSample': lastGateSessionPeakSample,
    };
  }

  /// Relay-only fields for debug logs (for example when the consumer socket
  /// disconnects). Skips histograms with no samples and counters still at
  /// zero so `flutter logs` stays readable.
  Map<String, Object?> relayDebugLogFields() {
    final out = <String, Object?>{};
    if (relayStreamingUnhandledErrorTotal != 0) {
      out['relayStreamingUnhandledErrors'] = relayStreamingUnhandledErrorTotal;
    }
    if (relayGzipDecodeIsolateTotal != 0) {
      out['relayGzipDecodeIsolateUses'] = relayGzipDecodeIsolateTotal;
    }
    if (relayJsonDecodeIsolateTotal != 0) {
      out['relayJsonDecodeIsolateUses'] = relayJsonDecodeIsolateTotal;
    }
    if (relayDecodeFailureTotalByCode.isNotEmpty) {
      out['relayDecodeFailureByCode'] = Map<String, int>.from(
        relayDecodeFailureTotalByCode,
      );
    }
    final decodeMs = relayPayloadDecodeWallClockMs;
    if (decodeMs.count > 0) {
      out['relayPayloadDecodeWallClockMs'] = _histogramDebugMap(decodeMs);
    }
    final encodeMs = relayPayloadEncodeWallClockMs;
    if (encodeMs.count > 0) {
      out['relayPayloadEncodeWallClockMs'] = _histogramDebugMap(encodeMs);
    }
    final firstChunk = relayAcceptToFirstChunkMs;
    if (firstChunk.count > 0) {
      out['relayAcceptToFirstChunkMs'] = _histogramDebugMap(firstChunk);
    }
    final reqToAcc = relayRequestToAcceptedMs;
    if (reqToAcc.count > 0) {
      out['relayRequestToAcceptedMs'] = _histogramDebugMap(reqToAcc);
    }
    final accToResp = relayAcceptedToResponseMs;
    if (accToResp.count > 0) {
      out['relayAcceptedToResponseMs'] = _histogramDebugMap(accToResp);
    }
    final convStart = relayConversationStartMs;
    if (convStart.count > 0) {
      out['relayConversationStartMs'] = _histogramDebugMap(convStart);
    }
    if (relayBatchEmissionsTotal > 0) {
      out['relayBatchEmissionsTotal'] = relayBatchEmissionsTotal;
    }
    if (relayBatchSizeDistribution.count > 0) {
      out['relayBatchSizeDistribution'] = _histogramDebugMap(
        relayBatchSizeDistribution,
      );
    }
    if (relayBatchPartialFailureTotal > 0) {
      out['relayBatchPartialFailureTotal'] = relayBatchPartialFailureTotal;
    }
    if (relayBatchBypassTotalByReason.isNotEmpty) {
      out['relayBatchBypassTotalByReason'] = Map<String, int>.from(
        relayBatchBypassTotalByReason,
      );
    }
    if (serverPhaseMsByName.isNotEmpty) {
      final entries = <String, Object?>{
        for (final entry in serverPhaseMsByName.entries)
          if (entry.value.count > 0) entry.key: _histogramDebugMap(entry.value),
      };
      if (entries.isNotEmpty) {
        out['serverPhaseMsByName'] = entries;
      }
    }
    if (serverTimingsSchemaMismatchTotal > 0) {
      out['serverTimingsSchemaMismatchTotal'] =
          serverTimingsSchemaMismatchTotal;
    }
    return out;
  }

  /// Compact payload for `AppLogger.info` on socket disconnect (release).
  Map<String, Object?> toCompactSessionExport() {
    return <String, Object?>{
      'handshakeP95Ms': handshakeMs.count > 0 ? handshakeMs.p95 : null,
      'handshakeCount': handshakeMs.count,
      'dispatchKeyCount': dispatchMsByKey.length,
      'relayDispatchKeyCount': relayDispatchMsByKey.length,
      'coalescedTotal': coalescedTotal,
      'batchEmissionsTotal': batchEmissionsTotal,
      'batchPartialFailureTotal': batchPartialFailureTotal,
      'gateWaiterQueueRejectedTotal': gateWaiterQueueRejectedTotal,
      'gateAcquireWaitTimeoutTotal': gateAcquireWaitTimeoutTotal,
      'lastGateSessionPeakSample': lastGateSessionPeakSample,
      'restFallbackLatchTotal': restFallbackLatchTotal,
      'outcomesTotal': outcomesTotal,
      'relayOutcomesTotal': relayOutcomesTotal,
      'reconnectsTotalByReason': reconnectsTotalByReason,
      ...relayDebugLogFields(),
    };
  }
}

Map<String, Object?> _histogramDebugMap(HistogramSnapshot h) {
  return <String, Object?>{
    'count': h.count,
    'mean': h.mean,
    'p50': h.p50,
    'p95': h.p95,
    'p99': h.p99,
    'max': h.max,
  };
}

/// Compact percentile view computed from an in-memory reservoir. The
/// implementation is sort-then-pick, so percentiles are exact for the
/// retained samples but bounded in cost by the reservoir size.
class HistogramSnapshot {
  const HistogramSnapshot({
    required this.count,
    required this.mean,
    required this.p50,
    required this.p95,
    required this.p99,
    required this.max,
  });

  static const HistogramSnapshot empty = HistogramSnapshot(
    count: 0,
    mean: 0,
    p50: 0,
    p95: 0,
    p99: 0,
    max: 0,
  );

  /// Total observations recorded (may exceed the reservoir size; the
  /// percentiles are computed only over the retained samples).
  final int count;

  /// Arithmetic mean over the retained samples (ms).
  final double mean;
  final double p50;
  final double p95;
  final double p99;
  final double max;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'count': count,
      'mean': mean,
      'p50': p50,
      'p95': p95,
      'p99': p99,
      'max': max,
    };
  }
}
