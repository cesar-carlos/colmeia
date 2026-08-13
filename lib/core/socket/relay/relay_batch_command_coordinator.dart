import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_sql_open_stream.dart';
import 'package:colmeia/core/socket/relay/relay_batch_item.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';

/// Coalesces concurrent unary `sendUnary` calls per `agentId` into a
/// single `relay:rpc.request.batch` envelope (hub item 1, v1 shipped
/// 2026-05-28). Mirrors `AgentCommandBatchCoordinator` for the relay
/// channel; integration guide:
/// `docs/server_adjustments/relay_rpc_batch_protocol.md`.
///
/// Bypasses to the inner dispatcher's [sendUnary] when an item must NOT
/// be batched in v1:
///
/// - streaming-capable (`prefer_db_streaming`, `multi_result`,
///   `sql.executeBatch`);
/// - `sql.cancel` (latency-critical);
/// - unrecognised body shape (no `command.method`).
///
/// Other channel surfaces (`sendStreaming`, `sendBatch`, `cancel`,
/// `outcomes`, `dispose`) forward to the inner dispatcher unchanged.
class RelayBatchCommandCoordinator implements RelayCommandDispatcher {
  RelayBatchCommandCoordinator({
    required RelayCommandDispatcher inner,
    Duration windowDuration = const Duration(milliseconds: 8),
    int maxBatchSize = 32,
    this.maxInflightPerAgent,
    void Function({required int size, required bool partialFailure})?
    onBatchEmission,
    void Function({required String reason})? onBypass,
  }) : assert(
         windowDuration >= Duration.zero,
         'windowDuration must be >= 0',
       ),
       assert(maxBatchSize >= 1, 'maxBatchSize must be >= 1'),
       assert(
         maxInflightPerAgent == null || maxInflightPerAgent > 0,
         'maxInflightPerAgent must be null or > 0',
       ),
       _inner = inner,
       _windowDuration = windowDuration,
       _maxBatchSize = _resolveMaxBatchSize(
         requested: maxBatchSize,
         maxInflightPerAgent: maxInflightPerAgent,
       ),
       _onBatchEmission = onBatchEmission,
       _onBypass = onBypass;

  final RelayCommandDispatcher _inner;
  final Duration _windowDuration;
  final int _maxBatchSize;

  /// Optional local per-agent concurrency ceiling. When set, [_maxBatchSize]
  /// never exceeds it so a flush cannot ask the gate for more slots than
  /// it can ever grant.
  final int? maxInflightPerAgent;
  final void Function({required int size, required bool partialFailure})?
  _onBatchEmission;
  final void Function({required String reason})? _onBypass;

  static int _resolveMaxBatchSize({
    required int requested,
    required int? maxInflightPerAgent,
  }) {
    final cappedByProtocol = requested > 32 ? 32 : requested;
    final ceiling = maxInflightPerAgent;
    if (ceiling == null || ceiling <= 0) {
      return cappedByProtocol;
    }
    return cappedByProtocol < ceiling ? cappedByProtocol : ceiling;
  }

  final Map<String, _RelayBatchCollector> _collectorsByAgent =
      <String, _RelayBatchCollector>{};
  bool _isDisposed = false;

  @override
  Future<Map<String, dynamic>> sendUnary({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? timeoutMs,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) {
    if (_isDisposed) {
      throw const RelayDispatcherDisposed(
        message: 'RelayBatchCommandCoordinator disposed',
      );
    }
    final bypass = _bypassReason(body);
    if (bypass != null) {
      _onBypass?.call(reason: bypass);
      return _inner.sendUnary(
        agentId: agentId,
        body: body,
        clientRequestId: clientRequestId,
        timeout: timeout,
        timeoutMs: timeoutMs,
        compression: compression,
      );
    }

    final collector = _collectorsByAgent.putIfAbsent(
      agentId,
      () => _RelayBatchCollector(
        agentId: agentId,
        compression: compression,
      ),
    );
    final completer = Completer<Map<String, dynamic>>();
    collector.queue.add(
      _BatchPending(
        item: RelayBatchItem(
          clientRequestId: clientRequestId,
          body: body,
          timeout: timeout,
          timeoutMs: timeoutMs,
        ),
        completer: completer,
      ),
    );

    if (collector.queue.length >= _maxBatchSize) {
      collector.flushTimer?.cancel();
      collector.flushTimer = null;
      unawaited(_flushCollector(collector));
    } else {
      collector.flushTimer ??= Timer(_windowDuration, () {
        collector.flushTimer = null;
        unawaited(_flushCollector(collector));
      });
    }
    return completer.future;
  }

  @override
  Stream<Map<String, dynamic>> sendStreaming({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    Duration? timeout,
    int? timeoutMs,
    int? initialWindowSize,
    int? refillThreshold,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) {
    // Streaming bypasses batching entirely (hub v1 rejects streaming
    // items in batch envelopes).
    return _inner.sendStreaming(
      agentId: agentId,
      body: body,
      clientRequestId: clientRequestId,
      timeout: timeout,
      timeoutMs: timeoutMs,
      initialWindowSize: initialWindowSize,
      refillThreshold: refillThreshold,
      compression: compression,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> sendBatch({
    required String agentId,
    required List<RelayBatchItem> items,
    Duration? timeout,
    int? timeoutMs,
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) {
    // Explicit batch goes straight to the wire; the caller already
    // owns grouping.
    return _inner.sendBatch(
      agentId: agentId,
      items: items,
      timeout: timeout,
      timeoutMs: timeoutMs,
      compression: compression,
    );
  }

  @override
  void cancel(String clientRequestId, {String reason = 'caller_cancelled'}) {
    // Cancellation is best-effort whether the request is pending in the
    // collector or already on the wire. Drop any queued pending so we
    // do not emit it in a future batch.
    for (final collector in _collectorsByAgent.values) {
      collector.queue.removeWhere((pending) {
        if (pending.item.clientRequestId != clientRequestId) {
          return false;
        }
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(
            RelayRequestCancelled(
              message: 'relay batch pending cancelled before emit',
              clientRequestId: clientRequestId,
            ),
          );
        }
        return true;
      });
    }
    _inner.cancel(clientRequestId, reason: reason);
  }

  @override
  List<AgentSqlOpenStream> cancelAllPending({
    String reason = 'caller_cancelled',
  }) {
    if (_isDisposed) {
      return const <AgentSqlOpenStream>[];
    }
    final queuedIds = <String>[];
    for (final collector in _collectorsByAgent.values) {
      for (final pending in collector.queue) {
        queuedIds.add(pending.item.clientRequestId);
      }
    }
    for (final clientRequestId in queuedIds) {
      cancel(clientRequestId, reason: reason);
    }
    return _inner.cancelAllPending(reason: reason);
  }

  @override
  Stream<RelayRpcOutcome> outcomes() => _inner.outcomes();

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    final collectors = List<_RelayBatchCollector>.of(_collectorsByAgent.values);
    _collectorsByAgent.clear();
    for (final collector in collectors) {
      collector.flushTimer?.cancel();
      collector.flushTimer = null;
      for (final pending in collector.queue) {
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(
            const RelayDispatcherDisposed(
              message: 'RelayBatchCommandCoordinator disposed',
            ),
          );
        }
      }
      collector.queue.clear();
    }
    await _inner.dispose();
  }

  Future<void> _flushCollector(_RelayBatchCollector collector) async {
    if (collector.queue.isEmpty) {
      return;
    }
    final taken = collector.queue.take(_maxBatchSize).toList(growable: false);
    collector.queue.removeRange(0, taken.length);

    final items = taken.map((pending) => pending.item).toList(growable: false);
    try {
      final responses = await _sendBatchWithOptionalSplit(
        agentId: collector.agentId,
        items: items,
        compression: collector.compression,
      );
      _completeTaken(taken, responses);
    } on Object catch (e, s) {
      _onBatchEmission?.call(size: taken.length, partialFailure: false);
      for (final pending in taken) {
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(e, s);
        }
      }
    }
  }

  /// Sends [items] as one batch. On hub `RATE_LIMITED` with
  /// `availableSlots > 0`, splits once into chunks of that size and
  /// retries with the same idempotent client request ids. A second
  /// `RATE_LIMITED` (or zero slots) propagates to the caller.
  Future<List<Map<String, dynamic>>> _sendBatchWithOptionalSplit({
    required String agentId,
    required List<RelayBatchItem> items,
    required RelayPayloadFrameCompression compression,
  }) async {
    try {
      return await _inner.sendBatch(
        agentId: agentId,
        items: items,
        compression: compression,
      );
    } on RelayRequestRejected catch (error) {
      final available = error.availableSlots;
      if (error.code != 'RATE_LIMITED' ||
          available == null ||
          available <= 0 ||
          available >= items.length) {
        rethrow;
      }
      AppLogger.warning(
        'Relay batch envelope RATE_LIMITED — splitting once',
        context: <String, Object?>{
          'component': 'RelayBatchCommandCoordinator',
          'agentId': agentId,
          'requested': items.length,
          'availableSlots': available,
          'requestedSlots': ?error.requestedSlots,
        },
      );
      final responses = <Map<String, dynamic>>[];
      for (var offset = 0; offset < items.length; offset += available) {
        final end = offset + available;
        final chunk = items.sublist(
          offset,
          end > items.length ? items.length : end,
        );
        final chunkResponses = await _inner.sendBatch(
          agentId: agentId,
          items: chunk,
          compression: compression,
        );
        responses.addAll(chunkResponses);
      }
      return responses;
    }
  }

  void _completeTaken(
    List<_BatchPending> taken,
    List<Map<String, dynamic>> responses,
  ) {
    var partial = false;
    if (responses.length != taken.length) {
      // Shouldn't happen given `sendBatch` resolves in caller order,
      // but defend against future contract drift.
      partial = true;
      AppLogger.warning(
        'Relay batch response length mismatch',
        context: <String, Object?>{
          'component': 'RelayBatchCommandCoordinator',
          'requested': taken.length,
          'received': responses.length,
        },
      );
    }
    for (var i = 0; i < taken.length; i++) {
      final pending = taken[i];
      if (pending.completer.isCompleted) {
        continue;
      }
      if (i >= responses.length) {
        pending.completer.completeError(
          RelayDecodeFailure(
            message: 'relay batch missing response for index $i',
            clientRequestId: pending.item.clientRequestId,
          ),
        );
        continue;
      }
      pending.completer.complete(responses[i]);
    }
    _onBatchEmission?.call(size: taken.length, partialFailure: partial);
  }

  /// Returns the bypass label (metric-friendly) or `null` when the body
  /// is eligible for the relay batch envelope.
  String? _bypassReason(Map<String, Object?> body) {
    final command = body['command'];
    if (command is! Map) {
      return 'unknown_method';
    }
    final method = command['method']?.toString();
    if (method == null || method.isEmpty) {
      return 'unknown_method';
    }
    if (method == 'sql.executeBatch') {
      return 'executeBatch';
    }
    if (method == 'sql.cancel') {
      return 'cancel';
    }
    final params = command['params'];
    if (params is Map) {
      final options = params['options'];
      if (options is Map) {
        if (options['multi_result'] == true) {
          return 'multi_result';
        }
        if (options['prefer_db_streaming'] == true) {
          return 'prefer_db_streaming';
        }
      }
    }
    return null;
  }
}

class _RelayBatchCollector {
  _RelayBatchCollector({
    required this.agentId,
    required this.compression,
  });

  final String agentId;
  final RelayPayloadFrameCompression compression;
  final List<_BatchPending> queue = <_BatchPending>[];
  Timer? flushTimer;
}

class _BatchPending {
  _BatchPending({required this.item, required this.completer});

  final RelayBatchItem item;
  final Completer<Map<String, dynamic>> completer;
}
