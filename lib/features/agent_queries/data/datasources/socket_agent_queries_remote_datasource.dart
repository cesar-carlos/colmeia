import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_agents_command_response_adapter.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_batch_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
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
    AgentSqlExecuteBatchRequestToBridgeBody batchBodyMapper =
        const AgentSqlExecuteBatchRequestToBridgeBody(),
  }) : _sender = sender,
       _bodyMapper = bodyMapper,
       _batchBodyMapper = batchBodyMapper;

  final AgentCommandSender _sender;
  final AgentSqlExecuteRequestToBridgeBody _bodyMapper;
  final AgentSqlExecuteBatchRequestToBridgeBody _batchBodyMapper;
  static const Uuid _uuid = Uuid();

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    if (cancelScope?.isCancelled ?? false) {
      return Future<Map<String, dynamic>>.error(
        const SocketDispatchCancelled(
          message: 'postSqlExecute skipped: AgentQueriesCancelScope cancelled',
        ),
      );
    }
    final rpcId = _uuid.v4();
    cancelScope?.trackPending(rpcId);
    final body = _bodyMapper.build(request: request, rpcId: rpcId);
    return _sender
        .send(
          agentId: request.trimmedAgentId,
          body: body,
          rpcId: rpcId,
          timeout: _resolveTimeout(request),
        )
        .then(
          (payload) => agentsCommandResponseToBridgeEnvelope(
            Map<String, dynamic>.from(payload),
            responseType: 'single',
          ),
        )
        .whenComplete(() => cancelScope?.untrackPending(rpcId));
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) {
    if (cancelScope?.isCancelled ?? false) {
      return Future<Map<String, dynamic>>.error(
        const SocketDispatchCancelled(
          message:
              'postSqlExecuteBatch skipped: AgentQueriesCancelScope cancelled',
        ),
      );
    }
    final rpcId = _uuid.v4();
    cancelScope?.trackPending(rpcId);
    final body = _batchBodyMapper.build(request: request, rpcId: rpcId);
    return _sender
        .send(
          agentId: request.trimmedAgentId,
          body: body,
          rpcId: rpcId,
          timeout: _resolveBatchTimeout(request),
        )
        .then(
          (payload) => agentsCommandResponseToBridgeEnvelope(
            Map<String, dynamic>.from(payload),
            responseType: 'batch',
          ),
        )
        .whenComplete(() => cancelScope?.untrackPending(rpcId));
  }

  /// Same +5s buffer the REST path applies to keep the client wait window
  /// slightly larger than the bridge wait window. See
  /// `agent_sql_http_receive_timeout.dart`.
  Duration _resolveTimeout(AgentSqlExecuteRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }

  Duration _resolveBatchTimeout(AgentSqlExecuteBatchRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }
}
