import 'dart:async';
import 'dart:collection';

import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/streaming_sql_execute_collector.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

/// Adapter that lets a repository **already wired to the unary
/// `AgentQueriesRemoteDataSource` port** benefit from the relay
/// streaming wire path with a single DI swap and zero behavioural
/// change at the call site.
///
/// Why exist: PR-L+ p3 already shipped a streaming-shaped port
/// (`AgentQueriesStreamingRemoteDataSource`) and PR-L+ p3.5 forwards
/// the `relay:rpc.complete` payload as the final stream item. Together
/// they make it possible to:
///
/// 1. Cross the wire as `relay:rpc.chunk` events (lower peak memory
///    on the hub, better backpressure handling) — see
///    `socket_relay_protocol.md` §"Confiabilidade e desempenho".
/// 2. Materialise the same `Map<String, dynamic>` shape that
///    `AgentSqlBridgeResponse.parseSuccess` understands today.
///
/// The repository keeps using `AgentQueriesRemoteDataSource`; the DI
/// swap chooses which transport (REST, `agents:command`, relay
/// unitary, **relay-collected**) actually runs.
///
/// [postSqlExecute] for the same `AgentSqlExecuteRequest.agentId` is limited
/// by `maxConcurrentPerAgent`. Calls above that ceiling wait for a slot so
/// dashboard waves can overlap without creating unbounded stream collectors.
class CollectingRelayStreamingAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  CollectingRelayStreamingAgentQueriesRemoteDataSource({
    required this._streamingDelegate,
    this._batchDelegate,
    this._collector = const BridgeShapedSqlExecuteCollector(),
    int maxConcurrentPerAgent = 4,
  }) : _maxConcurrentPerAgent = maxConcurrentPerAgent < 1
           ? 1
           : maxConcurrentPerAgent;

  final AgentQueriesStreamingRemoteDataSource _streamingDelegate;
  final AgentQueriesRemoteDataSource? _batchDelegate;
  final StreamingSqlExecuteCollector _collector;
  final int _maxConcurrentPerAgent;

  final Map<String, _PerAgentStreamingQueue> _queuesByAgentId =
      <String, _PerAgentStreamingQueue>{};

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    if (cancelScope?.isCancelled ?? false) {
      return Future<Map<String, dynamic>>.error(
        const RelayRequestCancelled(
          message: 'postSqlExecute skipped: AgentQueriesCancelScope already cancelled',
        ),
      );
    }
    final agentId = request.trimmedAgentId;
    late final _PerAgentStreamingQueue queue;
    queue = _queuesByAgentId.putIfAbsent(
      agentId,
      () => _PerAgentStreamingQueue(
        maxConcurrent: _maxConcurrentPerAgent,
        onIdle: () {
          if (identical(_queuesByAgentId[agentId], queue)) {
            _queuesByAgentId.remove(agentId);
          }
        },
      ),
    );
    return queue.run(
      () => _collector.collect(
        _streamingDelegate.streamSqlExecute(
          request,
          cancelScope: cancelScope,
        ),
        cancelScope: cancelScope,
      ),
      cancelScope: cancelScope,
    );
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    final batchDelegate = _batchDelegate;
    if (batchDelegate == null) {
      throw UnsupportedError(
        'Collected relay streaming does not support sql.executeBatch '
        'without a batch delegate',
      );
    }
    return batchDelegate.postSqlExecuteBatch(
      request,
      cancelScope: cancelScope,
    );
  }
}

class _PerAgentStreamingQueue {
  _PerAgentStreamingQueue({
    required this._maxConcurrent,
    required this._onIdle,
  });

  final int _maxConcurrent;
  final void Function() _onIdle;
  final Queue<_QueuedStreamingTask> _pending = Queue<_QueuedStreamingTask>();
  int _active = 0;

  Future<T> run<T>(
    Future<T> Function() work, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    if (cancelScope?.isCancelled ?? false) {
      return Future<T>.error(
        const RelayRequestCancelled(
          message: 'Streaming task skipped: AgentQueriesCancelScope already cancelled',
        ),
      );
    }
    final completer = Completer<T>();

    final task = _QueuedStreamingTask(
      run: () async {
        try {
          completer.complete(await work());
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
      cancel: () {
        if (!completer.isCompleted) {
          completer.completeError(
            const RelayRequestCancelled(
              message: 'Streaming task cancelled while waiting for a slot',
            ),
          );
        }
      },
    );

    if (_active < _maxConcurrent) {
      _start(task);
    } else {
      _pending.add(task);
      task.cancelRegistration = cancelScope?.registerLocalCancellation(
        () => _cancelQueued(task),
      );
    }
    return completer.future;
  }

  void _start(_QueuedStreamingTask task) {
    task.detachCancellation();
    _active += 1;
    unawaited(
      (() async {
        try {
          await task.run();
        } finally {
          _active -= 1;
          _drain();
        }
      })(),
    );
  }

  void _drain() {
    while (_active < _maxConcurrent && _pending.isNotEmpty) {
      _start(_pending.removeFirst());
    }
    if (_active == 0 && _pending.isEmpty) {
      _onIdle();
    }
  }

  void _cancelQueued(_QueuedStreamingTask task) {
    if (!_pending.remove(task)) {
      return;
    }
    task.detachCancellation();
    task.cancel();
    _drain();
  }
}

class _QueuedStreamingTask {
  _QueuedStreamingTask({required this.run, required this.cancel});

  final Future<void> Function() run;
  final void Function() cancel;
  void Function()? cancelRegistration;

  void detachCancellation() {
    final registration = cancelRegistration;
    cancelRegistration = null;
    registration?.call();
  }
}
