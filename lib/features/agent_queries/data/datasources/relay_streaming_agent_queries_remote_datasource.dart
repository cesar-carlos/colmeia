import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_transport_timeouts.dart';
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
    required this._dispatcher,
    this._bodyMapper = const AgentSqlExecuteRequestToBridgeBody(),
    this._compression = RelayPayloadFrameCompression.auto,
  });

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
        message: 'streamSqlExecute skipped: AgentQueriesCancelScope already cancelled',
      );
    }
    final clientRequestId = request.transportRpcId ?? _uuid.v4();
    cancelScope?.trackRelayPending(clientRequestId);
    AgentStreamingSqlCancelTarget? streamTarget;
    var completedNormally = false;

    void trackStreamId(String streamId) {
      final normalized = streamId.trim();
      if (normalized.isEmpty || streamTarget != null) {
        return;
      }
      final target = AgentStreamingSqlCancelTarget(
        agentId: request.trimmedAgentId,
        streamId: normalized,
        clientToken: request.trimmedClientToken,
      );
      streamTarget = target;
      cancelScope?.trackStreamingSql(target);
    }

    try {
      final body = _bodyMapper.buildRelayCommand(
        request: request,
        rpcId: clientRequestId,
        traceId: cancelScope?.traceId,
      );
      final stream = _sendStreaming(
        agentId: request.trimmedAgentId,
        body: body,
        clientRequestId: clientRequestId,
        timeout: agentSqlTransportDispatchTimeout(
          bridgeTimeoutMs: request.bridgeTimeoutMs,
        ),
        timeoutMs: request.bridgeTimeoutMs,
        onStreamOpened: cancelScope == null ? null : trackStreamId,
        compression: _resolveCompression(request.payloadFrameCompression),
      );
      yield* stream.map((chunk) {
        final streamId = _readStreamId(chunk);
        if (streamId != null) {
          trackStreamId(streamId);
        }
        return chunk;
      });
      completedNormally = true;
    } finally {
      final target = streamTarget;
      if (target != null) {
        if (completedNormally) {
          cancelScope?.untrackStreamingSql(target);
        } else {
          // A collector/protocol failure or subscription cancellation only
          // stops local pulls. Ask the hub to stop SQL work as well whenever
          // we already know the remote stream id.
          cancelScope?.cancelStreamingSql(target);
        }
      }
      cancelScope?.untrackRelayPending(clientRequestId);
    }
  }

  String? _readStreamId(Map<String, dynamic> chunk) {
    final raw = chunk['stream_id'] ?? chunk['streamId'];
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Stream<Map<String, dynamic>> _sendStreaming({
    required String agentId,
    required Map<String, Object?> body,
    required String clientRequestId,
    required Duration timeout,
    required int? timeoutMs,
    required RelayPayloadFrameCompression compression,
    void Function(String streamId)? onStreamOpened,
  }) {
    if (onStreamOpened == null) {
      return _dispatcher.sendStreaming(
        agentId: agentId,
        body: body,
        clientRequestId: clientRequestId,
        timeout: timeout,
        timeoutMs: timeoutMs,
        compression: compression,
      );
    }
    return _dispatcher.sendStreaming(
      agentId: agentId,
      body: body,
      clientRequestId: clientRequestId,
      timeout: timeout,
      timeoutMs: timeoutMs,
      onStreamOpened: onStreamOpened,
      compression: compression,
    );
  }

  RelayPayloadFrameCompression _resolveCompression(
    RelayPayloadFrameCompression? requestCompression,
  ) {
    return requestCompression ?? _compression;
  }
}
