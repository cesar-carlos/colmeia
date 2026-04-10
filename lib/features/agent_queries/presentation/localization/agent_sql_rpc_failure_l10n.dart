import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/l10n/app_localizations.dart';

/// Localized user-facing text for `RpcFailure` from agent SQL / bridge.
///
/// Policy for classification and `uiKey` assignment: see
/// `resolveAgentSqlRpcUserMessage` in
/// `agent_sql_rpc_user_message_resolver.dart`.
String agentSqlRpcFailureUserMessage(
  RpcFailure failure,
  AppLocalizations l10n,
) {
  final key = failure.context[AgentSqlRpcFailureUiKey.field] as String?;
  final preferBridge =
      failure.context[AgentSqlRpcFailureUiKey.preferBridgeUserMessageField] ==
      true;
  if ((key == AgentSqlRpcFailureUiKey.permissionDenied ||
          key == AgentSqlRpcFailureUiKey.sqlValidationFailed) &&
      preferBridge) {
    return failure.displayMessage;
  }
  if (key != null) {
    return switch (key) {
      AgentSqlRpcFailureUiKey.authenticationFailed =>
        l10n.agentSqlErrorAuthenticationFailed,
      AgentSqlRpcFailureUiKey.permissionDenied =>
        l10n.agentSqlErrorPermissionDenied,
      AgentSqlRpcFailureUiKey.transportTimeout =>
        l10n.agentSqlErrorTransportTimeout,
      AgentSqlRpcFailureUiKey.networkError => l10n.agentSqlErrorNetworkError,
      AgentSqlRpcFailureUiKey.rateLimited => l10n.agentSqlErrorRateLimited,
      AgentSqlRpcFailureUiKey.sqlValidationFailed =>
        l10n.agentSqlErrorValidationFailed,
      AgentSqlRpcFailureUiKey.sqlExecutionFailed =>
        l10n.agentSqlErrorExecutionFailed,
      AgentSqlRpcFailureUiKey.transactionFailed =>
        l10n.agentSqlErrorTransactionFailed,
      AgentSqlRpcFailureUiKey.connectionPoolExhausted =>
        l10n.agentSqlErrorConnectionPoolExhausted,
      AgentSqlRpcFailureUiKey.resultTooLarge =>
        l10n.agentSqlErrorResultTooLarge,
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
      _ => failure.displayMessage,
    };
  }
  return failure.displayMessage;
}
