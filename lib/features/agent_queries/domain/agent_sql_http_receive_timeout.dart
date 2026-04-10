/// Milliseconds added to the bridge wait (`timeoutMs` body field) so the HTTP
/// client outlives the agent and can still read the JSON response.
const int kAgentSqlHttpReceiveBufferMs = 5000;

/// Upper bound for computed receive timeout (avoids unbounded Duration).
const Duration kAgentSqlHttpReceiveTimeoutMax = Duration(
  minutes: 10,
  seconds: 5,
);

/// When the optional parameter is null or invalid, uses the same 15s default
/// Dio client `receiveTimeout` (keep in sync if that default changes).
const Duration kAgentSqlHttpDefaultReceiveTimeout = Duration(seconds: 15);

/// Receive timeout for `POST` agent SQL commands: aligns with the bridge body
/// field `timeoutMs` when set, else matches global API client defaults.
Duration agentSqlHttpReceiveTimeout({int? bridgeTimeoutMs}) {
  final timeout = bridgeTimeoutMs;
  if (timeout == null || timeout < 1) {
    return kAgentSqlHttpDefaultReceiveTimeout;
  }
  final ms = timeout + kAgentSqlHttpReceiveBufferMs;
  final computed = Duration(milliseconds: ms);
  return computed > kAgentSqlHttpReceiveTimeoutMax
      ? kAgentSqlHttpReceiveTimeoutMax
      : computed;
}
