import 'package:colmeia/features/agent_queries/domain/agent_sql_http_receive_timeout.dart';

/// Default bridge wait when the caller omits `bridgeTimeoutMs`.
const int kAgentSqlBridgeDefaultTimeoutMs = 15000;

/// Milliseconds added to the bridge wait so the transport client outlives the
/// agent-side timeout and can still read the terminal response.
const int kAgentSqlTransportReceiveBufferMs = kAgentSqlHttpReceiveBufferMs;

/// Dispatch timeout for socket/relay SQL: bridge wait + transport buffer.
Duration agentSqlTransportDispatchTimeout({int? bridgeTimeoutMs}) {
  final base = bridgeTimeoutMs ?? kAgentSqlBridgeDefaultTimeoutMs;
  return Duration(milliseconds: base + kAgentSqlTransportReceiveBufferMs);
}
