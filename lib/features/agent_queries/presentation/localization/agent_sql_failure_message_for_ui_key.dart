import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/l10n/app_localizations.dart';

/// Localized body copy for a stable [AgentSqlRpcFailureUiKey] value.
String agentSqlFailureMessageForUiKey(String key, AppLocalizations l10n) {
  return switch (key) {
    AgentSqlRpcFailureUiKey.authenticationFailed =>
      l10n.agentSqlErrorAuthenticationFailed,
    AgentSqlRpcFailureUiKey.permissionDenied =>
      l10n.agentSqlErrorPermissionDenied,
    AgentSqlRpcFailureUiKey.transportTimeout =>
      l10n.agentSqlErrorTransportTimeout,
    AgentSqlRpcFailureUiKey.networkError => l10n.agentSqlErrorNetworkError,
    AgentSqlRpcFailureUiKey.rateLimited => l10n.agentSqlErrorRateLimited,
    AgentSqlRpcFailureUiKey.replayDetected => l10n.agentSqlErrorReplayDetected,
    AgentSqlRpcFailureUiKey.sqlValidationFailed =>
      l10n.agentSqlErrorValidationFailed,
    AgentSqlRpcFailureUiKey.sqlExecutionFailed =>
      l10n.agentSqlErrorExecutionFailed,
    AgentSqlRpcFailureUiKey.transactionFailed =>
      l10n.agentSqlErrorTransactionFailed,
    AgentSqlRpcFailureUiKey.connectionPoolExhausted =>
      l10n.agentSqlErrorConnectionPoolExhausted,
    AgentSqlRpcFailureUiKey.resultTooLarge => l10n.agentSqlErrorResultTooLarge,
    AgentSqlRpcFailureUiKey.databaseConnectionFailed =>
      l10n.agentSqlErrorDatabaseConnectionFailed,
    AgentSqlRpcFailureUiKey.queryTimeout => l10n.agentSqlErrorQueryTimeout,
    AgentSqlRpcFailureUiKey.invalidDatabaseConfig =>
      l10n.agentSqlErrorInvalidDatabaseConfig,
    AgentSqlRpcFailureUiKey.executionNotFound =>
      l10n.agentSqlErrorExecutionNotFound,
    AgentSqlRpcFailureUiKey.executionCancelled =>
      l10n.agentSqlErrorExecutionCancelled,
    AgentSqlRpcFailureUiKey.generic => l10n.agentSqlErrorGeneric,
    _ => l10n.agentSqlErrorGeneric,
  };
}

/// Localized short title for error panels (category headline).
String agentSqlFailureTitleForUiKey(String key, AppLocalizations l10n) {
  return switch (key) {
    AgentSqlRpcFailureUiKey.authenticationFailed =>
      l10n.agentSqlFailureTitleAuthenticationFailed,
    AgentSqlRpcFailureUiKey.permissionDenied =>
      l10n.agentSqlFailureTitlePermissionDenied,
    AgentSqlRpcFailureUiKey.transportTimeout =>
      l10n.agentSqlFailureTitleTransportTimeout,
    AgentSqlRpcFailureUiKey.networkError => l10n.agentSqlFailureTitleNetworkError,
    AgentSqlRpcFailureUiKey.rateLimited => l10n.agentSqlFailureTitleRateLimited,
    AgentSqlRpcFailureUiKey.replayDetected =>
      l10n.agentSqlFailureTitleReplayDetected,
    AgentSqlRpcFailureUiKey.sqlValidationFailed =>
      l10n.agentSqlFailureTitleValidationFailed,
    AgentSqlRpcFailureUiKey.sqlExecutionFailed =>
      l10n.agentSqlFailureTitleExecutionFailed,
    AgentSqlRpcFailureUiKey.transactionFailed =>
      l10n.agentSqlFailureTitleTransactionFailed,
    AgentSqlRpcFailureUiKey.connectionPoolExhausted =>
      l10n.agentSqlFailureTitleConnectionPoolExhausted,
    AgentSqlRpcFailureUiKey.resultTooLarge =>
      l10n.agentSqlFailureTitleResultTooLarge,
    AgentSqlRpcFailureUiKey.databaseConnectionFailed =>
      l10n.agentSqlFailureTitleDatabaseConnectionFailed,
    AgentSqlRpcFailureUiKey.queryTimeout => l10n.agentSqlFailureTitleQueryTimeout,
    AgentSqlRpcFailureUiKey.invalidDatabaseConfig =>
      l10n.agentSqlFailureTitleInvalidDatabaseConfig,
    AgentSqlRpcFailureUiKey.executionNotFound =>
      l10n.agentSqlFailureTitleExecutionNotFound,
    AgentSqlRpcFailureUiKey.executionCancelled =>
      l10n.agentSqlFailureTitleExecutionCancelled,
    AgentSqlRpcFailureUiKey.generic => l10n.agentSqlFailureTitleGeneric,
    _ => l10n.agentSqlFailureTitleGeneric,
  };
}
