import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:uuid/uuid.dart';

/// Socket-channel datasource for `agent_queries`. Reuses
/// [AgentSqlExecuteRequestToBridgeBody] so the body sent through
/// `agents:command` is byte-for-byte identical to the REST body — this is
/// pinned by snapshot tests in `test/features/agent_queries/data/`.
///
/// Activated by setting `AGENT_BRIDGE_TRANSPORT=socket`. The repository
/// (`AgentQueriesRepositoryImpl`) is unchanged because the response shape
/// stays the same — even when the underlying [AgentCommandSender] is the
/// `AgentCommandBatchCoordinator` (PR-I), each caller still receives a
/// `single`-shaped response thanks to the synthesized envelope.
class SocketAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  SocketAgentQueriesRemoteDataSource({
    required AgentCommandSender sender,
    AgentSqlExecuteRequestToBridgeBody bodyMapper =
        const AgentSqlExecuteRequestToBridgeBody(),
  }) : _sender = sender,
       _bodyMapper = bodyMapper;

  final AgentCommandSender _sender;
  final AgentSqlExecuteRequestToBridgeBody _bodyMapper;
  static const Uuid _uuid = Uuid();

  @override
  Future<Map<String, dynamic>> postSqlExecute(AgentSqlExecuteRequest request) {
    final rpcId = _uuid.v4();
    final body = _bodyMapper.build(request: request, rpcId: rpcId);
    return _sender.send(
      agentId: request.trimmedAgentId,
      body: body,
      rpcId: rpcId,
      timeout: _resolveTimeout(request),
    );
  }

  /// Same +5s buffer the REST path applies to keep the client wait window
  /// slightly larger than the bridge wait window. See
  /// `agent_sql_http_receive_timeout.dart`.
  Duration _resolveTimeout(AgentSqlExecuteRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }
}
