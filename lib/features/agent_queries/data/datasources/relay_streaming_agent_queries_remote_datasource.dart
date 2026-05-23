import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:uuid/uuid.dart';

/// Streams `sql.execute` over relay using the JSON-RPC command as the
/// PayloadFrame logical payload.
///
/// REST and `agents:command` wrap the command in a bridge body. Relay does
/// not: the hub validates the decoded frame as the command itself, then
/// re-emits `relay:rpc.chunk`, `relay:rpc.complete`, or `relay:rpc.response`.
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
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async* {
    if (cancelScope?.isCancelled ?? false) {
      throw const RelayRequestCancelled(
        message:
            'streamSqlExecute skipped: AgentQueriesCancelScope already cancelled',
      );
    }
    final clientRequestId = _uuid.v4();
    cancelScope?.trackRelayPending(clientRequestId);
    try {
      final body = _bodyMapper.buildRelayCommand(
        request: request,
        rpcId: clientRequestId,
        traceId: cancelScope?.traceId,
      );
      yield* _trackStreamingIds(
        cancelScope: cancelScope,
        agentId: request.trimmedAgentId,
        clientToken: request.trimmedClientToken,
        stream: _dispatcher.sendStreaming(
          agentId: request.trimmedAgentId,
          body: body,
          clientRequestId: clientRequestId,
          timeout: _resolveTimeout(request),
          compression: _resolveCompression(request.payloadFrameCompression),
        ),
      );
    } finally {
      cancelScope?.untrackRelayPending(clientRequestId);
    }
  }

  Stream<Map<String, dynamic>> _trackStreamingIds({
    required Stream<Map<String, dynamic>> stream,
    required String agentId,
    AgentQueriesCancelScope? cancelScope,
    String? clientToken,
  }) {
    return stream.map((chunk) {
      final streamId = _readStreamId(chunk);
      if (streamId != null) {
        cancelScope?.trackStreamingSql(
          AgentStreamingSqlCancelTarget(
            agentId: agentId,
            streamId: streamId,
            clientToken: clientToken,
          ),
        );
      }
      return chunk;
    });
  }

  String? _readStreamId(Map<String, dynamic> chunk) {
    final raw = chunk['stream_id'] ?? chunk['streamId'];
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Same +5s buffer the unary paths apply: keeps the relay timeout
  /// one tick wider than the bridge wait window so the hub has a
  /// chance to surface its own JSON-RPC error before our deadline.
  Duration _resolveTimeout(AgentSqlExecuteRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }

  RelayPayloadFrameCompression _resolveCompression(
    RelayPayloadFrameCompression? requestCompression,
  ) {
    return requestCompression ?? _compression;
  }
}
