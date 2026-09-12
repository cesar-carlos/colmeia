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
/// same window share a single batch slot. Each caller still owns an
/// independent Future so it can cancel its local interest safely.
class AgentCommandBatchCoordinator implements AgentCommandSender {
  AgentCommandBatchCoordinator({
    required this._directSender,
    Duration windowDuration = const Duration(milliseconds: 8),
    int maxBatchSize = 32,
    int minBatchSize = 1,
    this._defaultTimeout = const Duration(seconds: 20),
    this._onBatchEmission,
    this._onBypass,
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
       _windowDuration = windowDuration,
       // Hard-cap to the hub's documented limit even if the env passes more.
       _maxBatchSize = maxBatchSize > 32 ? 32 : maxBatchSize,
       _minBatchSize = minBatchSize;

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
    // do not waste a batch slot on a duplicate. The wire item is shared,
    // but each caller receives its own cancellable completer.
    if (coalesceKey != null) {
      final existing = collector.coalesceMap[coalesceKey];
      if (existing != null && !existing.isDispatched) {
        final subscriber = existing.addSubscriber(
          rpcId: rpcId,
          timeout: timeout ?? _defaultTimeout,
        );
        collector.pendingByRpcId[rpcId] = existing;
        return subscriber.completer.future;
      }
    }

    final pending = _PendingRpc(
      rpcId: rpcId,
      bridgeTimeoutMs: _readBridgeTimeoutMs(body),
      command: _extractCommand(body),
      timeout: timeout ?? _defaultTimeout,
      enqueuedAt: DateTime.now(),
    );
    final subscriber = pending.addSubscriber(
      rpcId: rpcId,
      timeout: timeout ?? _defaultTimeout,
    );
    collector.queue.add(pending);
    collector.pendingByRpcId[rpcId] = pending;
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

    return subscriber.completer.future;
  }

  /// Cancels one logical caller, whether its batch item is still queued or
  /// has already been emitted. A dispatched batch keeps running for sibling
  /// items, but this caller's late response is discarded locally.
  ///
  /// Returns `true` when [rpcId] belongs to this coordinator. Callers use the
  /// value to decide whether they must fall through to the direct dispatcher.
  bool cancelPending(String rpcId, {String reason = 'caller_cancelled'}) {
    if (_isDisposed) {
      return false;
    }
    final error = SocketDispatchCancelled(
      message: 'Request cancelled by caller (reason=$reason)',
    );
    for (final collector in _collectorsByAgent.values) {
      final pending = collector.pendingByRpcId.remove(rpcId);
      if (pending == null) {
        continue;
      }
      final subscriber = pending.removeSubscriber(rpcId);
      if (subscriber != null && !subscriber.completer.isCompleted) {
        subscriber.completer.completeError(error);
      }
      if (pending.subscribers.isEmpty && !pending.isDispatched) {
        collector.queue.remove(pending);
        collector.coalesceMap.removeWhere(
          (_, value) => identical(value, pending),
        );
        if (collector.queue.isEmpty) {
          collector.flushTimer?.cancel();
          collector.flushTimer = null;
        }
      }
      return true;
    }
    return false;
  }

  /// Fail-fast every queued (not yet flushed) batch slot.
  void cancelAllQueued({String reason = 'caller_cancelled'}) {
    if (_isDisposed) {
      return;
    }
    final rpcIds = <String>[];
    for (final collector in _collectorsByAgent.values) {
      for (final pending in collector.queue) {
        rpcIds.addAll(pending.subscribers.keys);
      }
    }
    for (final rpcId in rpcIds) {
      cancelPending(rpcId, reason: reason);
    }
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
      final pending = Set<_PendingRpc>.of(collector.pendingByRpcId.values);
      for (final entry in pending) {
        _failPending(
          collector,
          entry,
          const SocketDispatchDisconnected(
            message: 'BatchCoordinator disposed',
          ),
        );
      }
      collector.queue.clear();
      collector.pendingByRpcId.clear();
    }
  }

  // ----- Internals -----

  Future<void> _flushCollector(_AgentBatchCollector collector) async {
    if (collector.queue.isEmpty) {
      return;
    }
    final taken = collector.queue.take(_maxBatchSize).toList(growable: false);
    collector.queue.removeRange(0, taken.length);
    for (final pending in taken) {
      pending.isDispatched = true;
    }
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
        await _dispatchAsSingle(
          collector: collector,
          agentId: collector.agentId,
          pending: pending,
        );
      }
      return;
    }

    await _dispatchBatch(
      collector: collector,
      agentId: collector.agentId,
      items: taken,
    );
  }

  Future<void> _dispatchAsSingle({
    required _AgentBatchCollector collector,
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
        timeout: pending.dispatchTimeout,
      );
      _completePending(collector, pending, response);
    } on Object catch (error, stack) {
      _failPending(collector, pending, error, stack);
    }
  }

  Future<void> _dispatchBatch({
    required _AgentBatchCollector collector,
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
        _failPending(collector, pending, failure, failureStack);
      }
      _onBatchEmission?.call(size: items.length, partialFailure: false);
      return;
    }

    final partialFailure = _distributeBatchResponse(
      agentId: agentId,
      collector: collector,
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
    required _AgentBatchCollector collector,
    required List<_PendingRpc> taken,
    required Map<String, dynamic> batchResponse,
  }) {
    final response = batchResponse['response'];
    if (response is! Map) {
      _failAll(
        collector,
        taken,
        _decodeFailure('response field missing/invalid'),
      );
      return true;
    }
    final type = response['type'];

    if (type == 'batch') {
      final items = response['items'];
      if (items is! List) {
        _failAll(collector, taken, _decodeFailure('batch items missing'));
        return true;
      }
      return _distributeBatchItems(
        agentId: agentId,
        collector: collector,
        byId: <String, _PendingRpc>{for (final p in taken) p.rpcId: p},
        items: items,
        commonRequestId: batchResponse['requestId']?.toString(),
      );
    }

    if (type == 'single' && taken.length == 1) {
      // Defensive fallback: hub may collapse a 1-item batch into a single
      // response. Pass it through unchanged.
      final only = taken.single;
      return _completePending(collector, only, batchResponse);
    }

    _failAll(
      collector,
      taken,
      _decodeFailure('unexpected response type: $type'),
    );
    return true;
  }

  bool _distributeBatchItems({
    required String agentId,
    required _AgentBatchCollector collector,
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
      if (raw['error'] != null) {
        sawError = true;
      }
      sawError =
          _completePending(
            collector,
            pending,
            _synthesizeSingleEnvelope(
              agentId: agentId,
              requestId: commonRequestId,
              item: raw,
            ),
            now: now,
          ) ||
          sawError;
    }
    for (final pending in unmatched.values) {
      sawError = true;
      _failPending(
        collector,
        pending,
        _decodeFailure('batch response did not include id=${pending.rpcId}'),
      );
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

  void _failAll(
    _AgentBatchCollector collector,
    List<_PendingRpc> pending,
    Object error,
  ) {
    for (final p in pending) {
      _failPending(collector, p, error);
    }
  }

  /// Completes every still-interested logical caller. Returns true when an
  /// individual caller timed out while its shared batch item was in flight.
  bool _completePending(
    _AgentBatchCollector collector,
    _PendingRpc pending,
    Map<String, dynamic> response, {
    DateTime? now,
  }) {
    final completedAt = now ?? DateTime.now();
    var timedOut = false;
    for (final subscriber in pending.subscribers.values.toList()) {
      collector.pendingByRpcId.remove(subscriber.rpcId);
      if (subscriber.completer.isCompleted) {
        continue;
      }
      final deadline = subscriber.enqueuedAt.add(subscriber.timeout);
      if (completedAt.isAfter(deadline)) {
        timedOut = true;
        subscriber.completer.completeError(
          SocketDispatchTimeout(
            message:
                'Batch item timed out waiting for batch response '
                '(rpcId=${subscriber.rpcId}, '
                'timeout=${subscriber.timeout.inSeconds}s)',
          ),
        );
      } else {
        subscriber.completer.complete(response);
      }
    }
    pending.subscribers.clear();
    return timedOut;
  }

  void _failPending(
    _AgentBatchCollector collector,
    _PendingRpc pending,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    for (final subscriber in pending.subscribers.values.toList()) {
      collector.pendingByRpcId.remove(subscriber.rpcId);
      if (!subscriber.completer.isCompleted) {
        if (stackTrace == null) {
          subscriber.completer.completeError(error);
        } else {
          subscriber.completer.completeError(error, stackTrace);
        }
      }
    }
    pending.subscribers.clear();
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
      if (p.dispatchTimeout > max) {
        max = p.dispatchTimeout;
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
    required this.timeout,
    required this.enqueuedAt,
  });

  final String rpcId;
  final int? bridgeTimeoutMs;
  final Map<String, Object?> command;
  final Duration timeout;
  final DateTime enqueuedAt;
  final Map<String, _BatchSubscriber> subscribers =
      <String, _BatchSubscriber>{};
  bool isDispatched = false;
  Duration _dispatchTimeout = Duration.zero;

  Duration get dispatchTimeout =>
      _dispatchTimeout > timeout ? _dispatchTimeout : timeout;

  _BatchSubscriber addSubscriber({
    required String rpcId,
    required Duration timeout,
  }) {
    final subscriber = _BatchSubscriber(
      rpcId: rpcId,
      timeout: timeout,
      enqueuedAt: DateTime.now(),
    );
    subscribers[rpcId] = subscriber;
    if (timeout > _dispatchTimeout) {
      _dispatchTimeout = timeout;
    }
    return subscriber;
  }

  _BatchSubscriber? removeSubscriber(String rpcId) => subscribers.remove(rpcId);
}

class _BatchSubscriber {
  _BatchSubscriber({
    required this.rpcId,
    required this.timeout,
    required this.enqueuedAt,
  });

  final String rpcId;
  final Duration timeout;
  final DateTime enqueuedAt;
  final Completer<Map<String, dynamic>> completer =
      Completer<Map<String, dynamic>>();
}

class _AgentBatchCollector {
  _AgentBatchCollector({required this.agentId});
  final String agentId;
  final List<_PendingRpc> queue = <_PendingRpc>[];
  final Map<String, _PendingRpc> coalesceMap = <String, _PendingRpc>{};
  final Map<String, _PendingRpc> pendingByRpcId = <String, _PendingRpc>{};
  Timer? flushTimer;
}
