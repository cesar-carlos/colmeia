import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/command_phase_observability.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_agents_command_response_adapter.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_batch_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_transport_timeouts.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:uuid/uuid.dart';

/// Socket-channel datasource for `agent_queries`. Reuses
/// [AgentSqlExecuteRequestToBridgeBody] so the body sent through
/// `agents:command` is byte-for-byte identical to the REST body — this is
/// pinned by snapshot tests in `test/features/agent_queries/data/`.
/// Each attempt uses a fresh wire id: the REST/legacy anti-replay guard rejects
/// repeated ids instead of replaying a deduplicated result as Relay does.
///
/// Activated by setting `AGENT_BRIDGE_TRANSPORT=socket`. The repository
/// (`AgentQueriesRepositoryImpl`) is unchanged because the response shape
/// stays the same — even when the underlying [AgentCommandSender] is the
/// `AgentCommandBatchCoordinator` (PR-I), each caller still receives a
/// `single`-shaped response thanks to the synthesized envelope.
class SocketAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  SocketAgentQueriesRemoteDataSource({
    required this._sender,
    this._bodyMapper = const AgentSqlExecuteRequestToBridgeBody(),
    this._batchBodyMapper = const AgentSqlExecuteBatchRequestToBridgeBody(),
  });

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
    cancelScope?.diagnostics?.route('socket_legacy');
    final rpcId = _uuid.v4();
    final body = _bodyMapper.build(request: request, rpcId: rpcId);
    cancelScope?.trackSocketPending(rpcId);
    final stopObserving = observeCommandPhases(
      _sender,
      rpcId,
      cancelScope?.diagnostics?.addDuration,
    );
    return _sender
        .send(
          agentId: request.trimmedAgentId,
          body: body,
          rpcId: rpcId,
          timeout: agentSqlTransportDispatchTimeout(
            bridgeTimeoutMs: request.bridgeTimeoutMs,
          ),
        )
        .then(
          (payload) {
            cancelScope?.diagnostics?.mark('first_response');
            return agentsCommandResponseToBridgeEnvelope(
              Map<String, dynamic>.from(payload),
              responseType: 'single',
            );
          },
        )
        .whenComplete(() {
          cancelScope?.untrackSocketPending(rpcId);
          stopObserving();
        });
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
    cancelScope?.diagnostics?.route('socket_legacy');
    final rpcId = _uuid.v4();
    final body = _batchBodyMapper.build(request: request, rpcId: rpcId);
    cancelScope?.trackSocketPending(rpcId);
    final stopObserving = observeCommandPhases(
      _sender,
      rpcId,
      cancelScope?.diagnostics?.addDuration,
    );
    return _sender
        .send(
          agentId: request.trimmedAgentId,
          body: body,
          rpcId: rpcId,
          timeout: agentSqlTransportDispatchTimeout(
            bridgeTimeoutMs: request.bridgeTimeoutMs,
          ),
        )
        .then(
          (payload) {
            cancelScope?.diagnostics?.mark('first_response');
            return agentsCommandResponseToBridgeEnvelope(
              Map<String, dynamic>.from(payload),
              responseType: 'batch',
            );
          },
        )
        .whenComplete(() {
          cancelScope?.untrackSocketPending(rpcId);
          stopObserving();
        });
  }
}
