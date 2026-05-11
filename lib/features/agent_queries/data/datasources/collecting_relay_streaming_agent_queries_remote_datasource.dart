import 'dart:async';

import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/streaming_sql_execute_collector.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';

void _ignoreChainedError(Object error, StackTrace stackTrace) {}

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
/// [postSqlExecute] for the same [AgentSqlExecuteRequest.agentId] is
/// **serialized**: a second call waits until the first `collect` fully
/// completes. That avoids overlapping `streamSqlExecute` sessions and
/// unbounded memory when many futures are started for one agent.
class CollectingRelayStreamingAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  CollectingRelayStreamingAgentQueriesRemoteDataSource({
    required AgentQueriesStreamingRemoteDataSource streamingDelegate,
    AgentQueriesRemoteDataSource? batchDelegate,
    StreamingSqlExecuteCollector collector =
        const BridgeShapedSqlExecuteCollector(),
  }) : _streamingDelegate = streamingDelegate,
       _batchDelegate = batchDelegate,
       _collector = collector;

  final AgentQueriesStreamingRemoteDataSource _streamingDelegate;
  final AgentQueriesRemoteDataSource? _batchDelegate;
  final StreamingSqlExecuteCollector _collector;

  final Map<String, Future<dynamic>> _postSqlTailByAgentId =
      <String, Future<dynamic>>{};

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) {
    final agentId = request.agentId;
    final previous = _postSqlTailByAgentId[agentId] ?? Future<void>.value();
    final mapped = previous
        .then<void>((_) {}, onError: _ignoreChainedError)
        .then(
          (_) => _collector.collect(
            _streamingDelegate.streamSqlExecute(request),
          ),
        );
    _postSqlTailByAgentId[agentId] = mapped.then<void>(
      (_) {},
      onError: _ignoreChainedError,
    );
    return mapped;
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request,
  ) {
    final batchDelegate = _batchDelegate;
    if (batchDelegate == null) {
      throw UnsupportedError(
        'Collected relay streaming does not support sql.executeBatch '
        'without a batch delegate',
      );
    }
    return batchDelegate.postSqlExecuteBatch(request);
  }
}
