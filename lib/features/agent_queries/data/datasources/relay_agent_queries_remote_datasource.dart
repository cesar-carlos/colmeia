import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_batch_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:uuid/uuid.dart';

/// Sends `sql.execute` over the relay channel (`relay:rpc.request`).
///
/// Reuses [AgentSqlExecuteRequestToBridgeBody] so the JSON-RPC payload is
/// byte-for-byte identical to the REST and `agents:command` paths — only
/// the wire wrapping (PayloadFrame envelope inside `relay:rpc.request`)
/// changes. The repository (`AgentQueriesRepositoryImpl`) keeps using the
/// same response parser because the hub re-emits `relay:rpc.response`
/// frames with the same bridge envelope (`response.type`, `response.item`).
///
/// Selection between this datasource and the unitary one
/// (`SocketAgentQueriesRemoteDataSource`) is a DI concern — see
/// `injector_agent_queries.dart` and the hybrid wrapper introduced in PR-L.
class RelayAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  RelayAgentQueriesRemoteDataSource({
    required RelayCommandDispatcher dispatcher,
    AgentSqlExecuteRequestToBridgeBody bodyMapper =
        const AgentSqlExecuteRequestToBridgeBody(),
    AgentSqlExecuteBatchRequestToBridgeBody batchBodyMapper =
        const AgentSqlExecuteBatchRequestToBridgeBody(),
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) : _dispatcher = dispatcher,
       _bodyMapper = bodyMapper,
       _batchBodyMapper = batchBodyMapper,
       _compression = compression;

  final RelayCommandDispatcher _dispatcher;
  final AgentSqlExecuteRequestToBridgeBody _bodyMapper;
  final AgentSqlExecuteBatchRequestToBridgeBody _batchBodyMapper;
  final RelayPayloadFrameCompression _compression;
  static const Uuid _uuid = Uuid();

  @override
  Future<Map<String, dynamic>> postSqlExecute(AgentSqlExecuteRequest request) {
    final clientRequestId = _uuid.v4();
    final body = _bodyMapper.build(request: request, rpcId: clientRequestId);
    return _dispatcher.sendUnary(
      agentId: request.trimmedAgentId,
      body: body,
      clientRequestId: clientRequestId,
      timeout: _resolveTimeout(request),
      compression: _compression,
    );
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request,
  ) {
    final clientRequestId = _uuid.v4();
    final body = _batchBodyMapper.build(
      request: request,
      rpcId: clientRequestId,
    );
    return _dispatcher.sendUnary(
      agentId: request.trimmedAgentId,
      body: body,
      clientRequestId: clientRequestId,
      timeout: _resolveBatchTimeout(request),
      compression: _compression,
    );
  }

  /// Same +5s buffer the REST and unitary socket paths apply, so the relay
  /// timeout sits one tick wider than the bridge wait window.
  Duration _resolveTimeout(AgentSqlExecuteRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }

  Duration _resolveBatchTimeout(AgentSqlExecuteBatchRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }
}
