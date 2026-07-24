import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/socket_coalesce_key.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:uuid/uuid.dart';

/// Coalesces concurrent `agents:command` requests targeting the same
/// `agentId` into a single JSON-RPC batch (`command: [...]`, max 32) and
/// distributes the per-item responses back to the original callers.
///
/// Detailed contract: `docs/Features/agent_command_batch_coordinator_design.md`.
///
/// Eligibility rules (auto-bypass to [_directSender]):
///
/// - body has top-level `pagination` (only valid for unitary `sql.execute`);
/// - method is `sql.executeBatch` (already a semantic batch);
/// - method is `sql.cancel` (latency-critical);
/// - `params.options.multi_result == true` (already multi-statement RPC);
/// - body has no recognizable `command.method`.
///
/// Coalescing inside the collector reuses the canonical key from
/// `SocketCoalesceKey`, ensuring that two identical pendings within the
/// same window share a single batch slot **and** the same Future.
class AgentCommandBatchCoordinator implements AgentCommandSender {
  AgentCommandBatchCoordinator({
    required AgentCommandSender directSender,
    Duration windowDuration = const Duration(milliseconds: 8),
    int maxBatchSize = 32,
    int minBatchSize = 1,
    Duration defaultTimeout = const Duration(seconds: 20),
    void Function({required int size, required bool partialFailure})?
    onBatchEmission,
    void Function({required String reason})? onBypass,
  }) : assert(
         windowDuration >= Duration.zero,
         'windowDuration must be >= 0',
       ),
       assert(maxBatchSize >= 1, 'maxBatchSize must be >= 1'),
       assert(minBatchSize >= 1, 'minBatchSize must be >= 1'),
       assert(
         minBatchSize <= maxBatchSize,
         'minBatchSize must be <= maxBatchSize',
       ),
       _directSender = directSender,
       _windowDuration = windowDuration,
       // Hard-cap to the hub's documented limit even if the env passes more.
       _maxBatchSize = maxBatchSize > 32 ? 32 : maxBatchSize,
       _minBatchSize = minBatchSize,
       _defaultTimeout = defaultTimeout,
       _onBatchEmission = onBatchEmission,
       _onBypass = onBypass;

  final AgentCommandSender _directSender;
  final Duration _windowDuration;
  final int _maxBatchSize;
  final int _minBatchSize;
  final Duration _defaultTimeout;
  final void Function({required int size, required bool partialFailure})?
  _onBatchEmission;
  final void Function({required String reason})? _onBypass;
  static const Uuid _uuid = Uuid();

  final Map<String, _AgentBatchCollector> _collectorsByAgent =
      <String, _AgentBatchCollector>{};
  bool _isDisposed = false;

  @override
  Future<Map<String, dynamic>> send({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) async {
    if (_isDisposed) {
      throw const SocketDispatchDisconnected(
        message: 'BatchCoordinator disposed',
      );
    }

    final bypassReason = _bypassReason(body);
    if (bypassReason != null) {
      _onBypass?.call(reason: bypassReason);
      return _directSender.send(
        agentId: agentId,
        body: body,
        rpcId: rpcId,
        timeout: timeout,
      );
    }

    final coalesceKey = SocketCoalesceKey.compute(agentId: agentId, body: body);

    final collector = _collectorsByAgent.putIfAbsent(
      agentId,
      () => _AgentBatchCollector(agentId: agentId),
    );

    // Coalesce identical pendings within the same collector window so we
    // do not waste a batch slot on a duplicate. Returns the existing
    // Future when the dedupe match is still alive.
    if (coalesceKey != null) {
      final existing = collector.coalesceMap[coalesceKey];
      if (existing != null && !existing.completer.isCompleted) {
        return existing.completer.future;
      }
    }

    final completer = Completer<Map<String, dynamic>>();
    final pending = _PendingRpc(
      rpcId: rpcId,
      bridgeTimeoutMs: _readBridgeTimeoutMs(body),
      command: _extractCommand(body),
      completer: completer,
      timeout: timeout ?? _defaultTimeout,
      enqueuedAt: DateTime.now(),
    );
    collector.queue.add(pending);
    if (coalesceKey != null) {
      collector.coalesceMap[coalesceKey] = pending;
    }

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

  /// Removes a queued (not yet flushed) RPC from the collector window.
  /// Returns `true` when [rpcId] was found and cancelled.
  bool cancelPending(String rpcId, {String reason = 'caller_cancelled'}) {
    if (_isDisposed) {
      return false;
    }
    final error = SocketDispatchCancelled(
      message: 'Request cancelled by caller (reason=$reason)',
    );
    for (final collector in _collectorsByAgent.values) {
      final index = collector.queue.indexWhere((p) => p.rpcId == rpcId);
      if (index < 0) {
        continue;
      }
      final pending = collector.queue.removeAt(index);
      collector.coalesceMap.removeWhere(
        (_, value) => identical(value, pending),
      );
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(error);
      }
      if (collector.queue.isEmpty) {
        collector.flushTimer?.cancel();
        collector.flushTimer = null;
      }
      return true;
    }
    return false;
  }

  /// Forces flush across every agent. Useful for sign-out and dispose.
  ///
  /// Cancels any pending flush timers before dispatching so the timer
  /// cannot fire a redundant _flushCollector call on an already-cleared
  /// collector (and cannot cause a double-flush race).
  Future<void> flushAll() async {
    final collectors = List<_AgentBatchCollector>.of(
      _collectorsByAgent.values,
    );
    for (final collector in collectors) {
      collector.flushTimer?.cancel();
      collector.flushTimer = null;
    }
    await Future.wait(collectors.map(_flushCollector));
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    final collectors = List<_AgentBatchCollector>.of(
      _collectorsByAgent.values,
    );
    _collectorsByAgent.clear();
    for (final collector in collectors) {
      collector.flushTimer?.cancel();
      collector.coalesceMap.clear();
      for (final pending in collector.queue) {
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(
            const SocketDispatchDisconnected(
              message: 'BatchCoordinator disposed',
            ),
          );
        }
      }
      collector.queue.clear();
    }
  }

  // ----- Internals -----

  Future<void> _flushCollector(_AgentBatchCollector collector) async {
    if (collector.queue.isEmpty) {
      return;
    }
    final taken = collector.queue.take(_maxBatchSize).toList(growable: false);
    collector.queue.removeRange(0, taken.length);
    // Clear the coalesce map for everything we are about to dispatch.
    final coalesceKeysToDrop = <String>[];
    collector.coalesceMap.forEach((key, pending) {
      if (taken.contains(pending)) {
        coalesceKeysToDrop.add(key);
      }
    });
    coalesceKeysToDrop.forEach(collector.coalesceMap.remove);

    if (taken.length < _minBatchSize) {
      for (final pending in taken) {
        await _dispatchAsSingle(agentId: collector.agentId, pending: pending);
      }
      return;
    }

    await _dispatchBatch(agentId: collector.agentId, items: taken);
  }

  Future<void> _dispatchAsSingle({
    required String agentId,
    required _PendingRpc pending,
  }) async {
    final body = _buildSingleBody(
      agentId: agentId,
      command: pending.command,
      bridgeTimeoutMs: pending.bridgeTimeoutMs,
    );
    try {
      final response = await _directSender.send(
        agentId: agentId,
        body: body,
        rpcId: pending.rpcId,
        timeout: pending.timeout,
      );
      if (!pending.completer.isCompleted) {
        pending.completer.complete(response);
      }
    } on Object catch (error, stack) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(error, stack);
      }
    }
  }

  Future<void> _dispatchBatch({
    required String agentId,
    required List<_PendingRpc> items,
  }) async {
    final batchRpcId = 'batch-${_uuid.v4()}';
    final timeout = _resolveBatchTimeout(items);
    final body = _buildBatchBody(
      agentId: agentId,
      items: items,
    );

    AppLogger.debug(
      'Dispatching agents:command batch',
      context: <String, Object?>{
        'component': 'AgentCommandBatchCoordinator',
        'agentId': agentId,
        'batchSize': items.length,
        'batchRpcId': batchRpcId,
      },
    );

    Map<String, dynamic>? response;
    Object? failure;
    StackTrace? failureStack;
    try {
      response = await _directSender.send(
        agentId: agentId,
        body: body,
        rpcId: batchRpcId,
        timeout: timeout,
      );
    } on Object catch (error, stack) {
      failure = error;
      failureStack = stack;
    }

    if (failure != null) {
      // Total failure: every pending receives the same error.
      for (final pending in items) {
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(failure, failureStack);
        }
      }
      _onBatchEmission?.call(size: items.length, partialFailure: false);
      return;
    }

    final partialFailure = _distributeBatchResponse(
      agentId: agentId,
      taken: items,
      batchResponse: response!,
    );
    _onBatchEmission?.call(
      size: items.length,
      partialFailure: partialFailure,
    );
  }

  /// Returns `true` when at least one item came back with an error or was
  /// not present in the response.
  bool _distributeBatchResponse({
    required String agentId,
    required List<_PendingRpc> taken,
    required Map<String, dynamic> batchResponse,
  }) {
    final response = batchResponse['response'];
    if (response is! Map) {
      _failAll(taken, _decodeFailure('response field missing/invalid'));
      return true;
    }
    final type = response['type'];

    if (type == 'batch') {
      final items = response['items'];
      if (items is! List) {
        _failAll(taken, _decodeFailure('batch items missing'));
        return true;
      }
      return _distributeBatchItems(
        agentId: agentId,
        byId: <String, _PendingRpc>{for (final p in taken) p.rpcId: p},
        items: items,
        commonRequestId: batchResponse['requestId']?.toString(),
      );
    }

    if (type == 'single' && taken.length == 1) {
      // Defensive fallback: hub may collapse a 1-item batch into a single
      // response. Pass it through unchanged.
      final only = taken.single;
      if (!only.completer.isCompleted) {
        only.completer.complete(batchResponse);
      }
      return false;
    }

    _failAll(taken, _decodeFailure('unexpected response type: $type'));
    return true;
  }

  bool _distributeBatchItems({
    required String agentId,
    required Map<String, _PendingRpc> byId,
    required List<dynamic> items,
    required String? commonRequestId,
  }) {
    final unmatched = Map<String, _PendingRpc>.of(byId);
    final now = DateTime.now();
    var sawError = false;
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final id = raw['id']?.toString();
      if (id == null) {
        continue;
      }
      final pending = unmatched.remove(id);
      if (pending == null) {
        AppLogger.warning(
          'Batch item id not in pending map (late or duplicate)',
          context: <String, Object?>{
            'component': 'AgentCommandBatchCoordinator',
            'rpcId': id,
          },
        );
        continue;
      }
      // Enforce individual timeout: if the item's own deadline elapsed while
      // waiting in the batch window, fail it instead of completing with stale
      // data. This restores the semantics the caller configured via `timeout`.
      final deadline = pending.enqueuedAt.add(pending.timeout);
      if (now.isAfter(deadline)) {
        sawError = true;
        AppLogger.debug(
          'Batch item individual timeout expired at distribution',
          context: <String, Object?>{
            'component': 'AgentCommandBatchCoordinator',
            'rpcId': id,
            'timeoutMs': pending.timeout.inMilliseconds,
          },
        );
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(
            SocketDispatchTimeout(
              message:
                  'Batch item timed out waiting for batch response '
                  '(rpcId=$id, timeout=${pending.timeout.inSeconds}s)',
            ),
          );
        }
        continue;
      }
      if (raw['error'] != null) {
        sawError = true;
      }
      if (!pending.completer.isCompleted) {
        pending.completer.complete(
          _synthesizeSingleEnvelope(
            agentId: agentId,
            requestId: commonRequestId,
            item: raw,
          ),
        );
      }
    }
    for (final pending in unmatched.values) {
      sawError = true;
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(
          _decodeFailure(
            'batch response did not include id=${pending.rpcId}',
          ),
        );
      }
    }
    return sawError;
  }

  /// Wraps a batch item as if it were a `single` `agents:command_response`,
  /// keeping `AgentSqlBridgeResponse.parseSuccess` untouched in the
  /// repository layer.
  Map<String, dynamic> _synthesizeSingleEnvelope({
    required String agentId,
    required String? requestId,
    required Map<String, dynamic> item,
  }) {
    return <String, dynamic>{
      'mode': 'bridge',
      'agentId': agentId,
      'requestId': ?requestId,
      'response': <String, dynamic>{
        'type': 'single',
        'success': item['success'] ?? (item['error'] == null),
        'item': item,
      },
    };
  }

  void _failAll(List<_PendingRpc> pending, Object error) {
    for (final p in pending) {
      if (!p.completer.isCompleted) {
        p.completer.completeError(error);
      }
    }
  }

  SocketDispatchDecodeFailure _decodeFailure(String message) {
    return SocketDispatchDecodeFailure(message: 'batch decode: $message');
  }

  /// Returns the bypass reason as a metric label, or `null` when the body
  /// is batch-eligible.
  String? _bypassReason(Map<String, Object?> body) {
    if (body['pagination'] != null) {
      return 'paginated';
    }
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
      if (options is Map && options['multi_result'] == true) {
        return 'multi_result';
      }
    }
    return null;
  }

  Map<String, Object?> _extractCommand(Map<String, Object?> body) {
    final command = body['command'];
    if (command is Map) {
      return Map<String, Object?>.from(command.cast<String, Object?>());
    }
    throw ArgumentError(
      'BatchCoordinator received body without `command` map',
    );
  }

  Map<String, Object?> _buildSingleBody({
    required String agentId,
    required Map<String, Object?> command,
    required int? bridgeTimeoutMs,
  }) {
    return <String, Object?>{
      'agentId': agentId,
      'timeoutMs': ?bridgeTimeoutMs,
      'command': command,
    };
  }

  Map<String, Object?> _buildBatchBody({
    required String agentId,
    required List<_PendingRpc> items,
  }) {
    return <String, Object?>{
      'agentId': agentId,
      'timeoutMs': ?_resolveBridgeBatchTimeoutMs(items),
      // Body-level pagination is intentionally omitted: it is invalid for
      // batch payloads (hub spec).
      'command': items.map((p) => p.command).toList(growable: false),
    };
  }

  Duration _resolveBatchTimeout(List<_PendingRpc> items) {
    var max = _defaultTimeout;
    for (final p in items) {
      if (p.timeout > max) {
        max = p.timeout;
      }
    }
    return max;
  }

  int? _readBridgeTimeoutMs(Map<String, Object?> body) {
    final raw = body['timeoutMs'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  int? _resolveBridgeBatchTimeoutMs(List<_PendingRpc> items) {
    int? max;
    for (final item in items) {
      final value = item.bridgeTimeoutMs;
      if (value != null && (max == null || value > max)) {
        max = value;
      }
    }
    return max;
  }
}

class _PendingRpc {
  _PendingRpc({
    required this.rpcId,
    required this.bridgeTimeoutMs,
    required this.command,
    required this.completer,
    required this.timeout,
    required this.enqueuedAt,
  });

  final String rpcId;
  final int? bridgeTimeoutMs;
  final Map<String, Object?> command;
  final Completer<Map<String, dynamic>> completer;
  final Duration timeout;
  final DateTime enqueuedAt;
}

class _AgentBatchCollector {
  _AgentBatchCollector({required this.agentId});
  final String agentId;
  final List<_PendingRpc> queue = <_PendingRpc>[];
  final Map<String, _PendingRpc> coalesceMap = <String, _PendingRpc>{};
  Timer? flushTimer;
}
