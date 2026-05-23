import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:uuid/uuid.dart';

/// Maps an [AgentSqlExecuteRequest] into the bridge body shared by REST and
/// the legacy socket command path:
///
/// - REST: body of `POST /api/v1/agents/commands`.
/// - Socket: payload of the `agents:command` event on the `/consumers`
///   namespace.
///
/// Keeping a single mapper guarantees byte-for-byte parity between channels;
/// any divergence is a bug. Snapshot tests in
/// `test/features/agent_queries/data/agent_sql_execute_request_to_bridge_body_test.dart`
/// pin the wire format.
///
/// Relay (`relay:rpc.request`) is different: the `PayloadFrame` logical
/// payload is the JSON-RPC command itself, not this REST body. Use
/// [buildRelayCommand] for relay datasources.
class AgentSqlExecuteRequestToBridgeBody {
  const AgentSqlExecuteRequestToBridgeBody();

  /// Builds the full body to send. The caller passes the already-generated
  /// JSON-RPC `command.id` ([rpcId]) so the same id can be used to correlate
  /// the response — [rpcId] must NOT be generated inside this helper.
  Map<String, Object?> build({
    required AgentSqlExecuteRequest request,
    required String rpcId,
  }) {
    final payloadFrameCompression = request.payloadFrameCompression?.wireValue;

    return <String, Object?>{
      'agentId': request.trimmedAgentId,
      'timeoutMs': ?request.bridgeTimeoutMs,
      'pagination': ?request.pagination?.toHttpBody(),
      'payloadFrameCompression': ?payloadFrameCompression,
      'command': _buildJsonRpcCommand(
        request: request,
        rpcId: rpcId,
        includePaginationInOptions: false,
      ),
    };
  }

  /// Builds the JSON-RPC command used as the logical PayloadFrame payload on
  /// `relay:rpc.request`.
  Map<String, Object?> buildRelayCommand({
    required AgentSqlExecuteRequest request,
    required String rpcId,
    String? traceId,
  }) {
    return _buildJsonRpcCommand(
      request: request,
      rpcId: rpcId,
      includePaginationInOptions: true,
      traceId: traceId,
    );
  }

  Map<String, Object?> _buildJsonRpcCommand({
    required AgentSqlExecuteRequest request,
    required String rpcId,
    required bool includePaginationInOptions,
    String? traceId,
  }) {
    final trimmedToken = request.trimmedClientToken;
    final rpcOptions = includePaginationInOptions
        ? _buildRelayRpcOptions(
            executeOptions: request.executeOptions,
            pagination: request.pagination,
          )
        : request.executeOptions?.toRpcOptions();
    final namedParams = request.namedParams.isEmpty
        ? null
        : request.namedParams;
    final clientToken = trimmedToken == null || trimmedToken.isEmpty
        ? null
        : trimmedToken;

    final params = <String, Object?>{
      'sql': _normalizeSqlForRpc(request.trimmedSql),
      'params': ?namedParams,
      'client_token': ?clientToken,
      'options': ?rpcOptions,
    };

    final outboundCompression = request.outboundCompression?.wireValue;
    final meta = <String, Object?>{
      'trace_id': traceId ?? const Uuid().v4(),
      'outbound_compression': ?outboundCompression,
    };

    final apiVersion = request.apiVersion.trim();

    return <String, Object?>{
      'jsonrpc': '2.0',
      'method': 'sql.execute',
      'id': rpcId,
      if (apiVersion.isNotEmpty) 'api_version': apiVersion,
      'meta': meta,
      'params': params,
    };
  }
}

String _normalizeSqlForRpc(String sql) =>
    sql.replaceAll(RegExp(r'\s*\r?\n\s*'), ' ').trim();

Map<String, Object?>? _buildRelayRpcOptions({
  AgentSqlExecuteOptions? executeOptions,
  AgentSqlBridgePagination? pagination,
}) {
  final map = <String, Object?>{};
  final execOpts = executeOptions?.toRpcOptions();
  if (execOpts != null) {
    map.addAll(execOpts);
  }
  final paginationOpts = pagination?.toRpcOptions();
  if (paginationOpts != null) {
    map.addAll(paginationOpts);
  }
  return map.isEmpty ? null : map;
}
