/// Context field names for mapping SQL/RPC failures to localized strings.
abstract final class AgentSqlRpcFailureUiKey {
  static const String field = 'agentSqlRpcFailureUiKey';

  /// When true, presentation should use the RPC user message (bridge copy).
  static const String preferBridgeUserMessageField =
      'agentSqlRpcPreferBridgeUserMessage';

  /// Full JSON-RPC `error.data` map (unmodifiable), for logs and future rules.
  static const String errorDataField = 'agentSqlRpcErrorData';

  static const String authenticationFailed = 'authenticationFailed';
  static const String permissionDenied = 'permissionDenied';
  static const String transportTimeout = 'transportTimeout';
  static const String networkError = 'networkError';
  static const String rateLimited = 'rateLimited';
  static const String sqlValidationFailed = 'sqlValidationFailed';
  static const String sqlExecutionFailed = 'sqlExecutionFailed';
  static const String transactionFailed = 'transactionFailed';
  static const String connectionPoolExhausted = 'connectionPoolExhausted';
  static const String resultTooLarge = 'resultTooLarge';
  static const String databaseConnectionFailed = 'databaseConnectionFailed';
  static const String queryTimeout = 'queryTimeout';
  static const String invalidDatabaseConfig = 'invalidDatabaseConfig';
  static const String executionNotFound = 'executionNotFound';
  static const String executionCancelled = 'executionCancelled';
  static const String generic = 'generic';
}
