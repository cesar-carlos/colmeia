/// Optional hook for appending SQL repository metrics to a consumer socket
/// session export (disconnect / error). Implemented in the agent_queries
/// feature; the socket listener stays in `core/` without importing features.
typedef SocketSqlMetricsAppendixProvider = Map<String, Object?> Function();
