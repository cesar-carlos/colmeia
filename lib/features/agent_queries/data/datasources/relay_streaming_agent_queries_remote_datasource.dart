import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:uuid/uuid.dart';

/// Streams `sql.execute` over the relay channel using
/// `RelayCommandDispatcher.sendStreaming`. Reuses
/// [AgentSqlExecuteRequestToBridgeBody] so the body is byte-for-byte
/// identical to the REST and `agents:command` paths — only the wire
/// wrapping (PayloadFrame envelope + chunked relay events) changes.
///
/// PR-L+ p3 ships this as a standalone datasource. Wiring it into a
/// concrete `AgentQueryExecutor` flow is a follow-up sub-PR that
/// needs to identify which `overview` query benefits from streaming
/// (see `socket_consumer_channel_plan.md` §0.3).
class RelayStreamingAgentQueriesRemoteDataSource
    implements AgentQueriesStreamingRemoteDataSource {
  RelayStreamingAgentQueriesRemoteDataSource({
    required RelayCommandDispatcher dispatcher,
    AgentSqlExecuteRequestToBridgeBody bodyMapper =
        const AgentSqlExecuteRequestToBridgeBody(),
    RelayPayloadFrameCompression compression =
        RelayPayloadFrameCompression.auto,
  }) : _dispatcher = dispatcher,
       _bodyMapper = bodyMapper,
       _compression = compression;

  final RelayCommandDispatcher _dispatcher;
  final AgentSqlExecuteRequestToBridgeBody _bodyMapper;
  final RelayPayloadFrameCompression _compression;
  static const Uuid _uuid = Uuid();

  @override
  Stream<Map<String, dynamic>> streamSqlExecute(
    AgentSqlExecuteRequest request,
  ) {
    final clientRequestId = _uuid.v4();
    final body = _bodyMapper.build(request: request, rpcId: clientRequestId);
    return _dispatcher.sendStreaming(
      agentId: request.trimmedAgentId,
      body: body,
      clientRequestId: clientRequestId,
      timeout: _resolveTimeout(request),
      compression: _compression,
    );
  }

  /// Same +5s buffer the unary paths apply: keeps the relay timeout
  /// one tick wider than the bridge wait window so the hub has a
  /// chance to surface its own JSON-RPC error before our deadline.
  Duration _resolveTimeout(AgentSqlExecuteRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }
}
