import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/streaming_sql_execute_collector.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';

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
class CollectingRelayStreamingAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  CollectingRelayStreamingAgentQueriesRemoteDataSource({
    required AgentQueriesStreamingRemoteDataSource streamingDelegate,
    StreamingSqlExecuteCollector collector =
        const BridgeShapedSqlExecuteCollector(),
  }) : _streamingDelegate = streamingDelegate,
       _collector = collector;

  final AgentQueriesStreamingRemoteDataSource _streamingDelegate;
  final StreamingSqlExecuteCollector _collector;

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) {
    return _collector.collect(_streamingDelegate.streamSqlExecute(request));
  }
}
