import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_failure_message_for_ui_key.dart';
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
  final key = resolveAgentQueryFailureUiKey(failure);
  final preferBridge =
      failure.context[AgentSqlRpcFailureUiKey.preferBridgeUserMessageField] ==
      true;
  if ((key == AgentSqlRpcFailureUiKey.permissionDenied ||
          key == AgentSqlRpcFailureUiKey.sqlValidationFailed) &&
      preferBridge) {
    return failure.displayMessage;
  }
  if (key != null) {
    return agentSqlFailureMessageForUiKey(key, l10n);
  }
  return failure.displayMessage;
}
