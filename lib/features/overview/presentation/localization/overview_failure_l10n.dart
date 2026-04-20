import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_rpc_failure_l10n.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/l10n/app_localizations.dart';

/// Maps failures from overview load (including nested SQL/RPC) to localized
/// user-facing text.
///
/// SQL/RPC policy: see `resolveAgentSqlRpcUserMessage` in
/// `agent_sql_rpc_user_message_resolver.dart`.
String overviewFailureUserMessage(
  AppFailure failure,
  AppLocalizations l10n,
) {
  final overviewKey = failure.context[OverviewFailureUiKey.field] as String?;
  if (overviewKey != null) {
    return switch (overviewKey) {
      OverviewFailureUiKey.noApprovedAgents =>
        l10n.overviewNoApprovedAgentsUserMessage,
      OverviewFailureUiKey.loadFailed => l10n.overviewLoadFailedUserMessage,
      _ => failure.displayMessage,
    };
  }

  if (failure is RpcFailure) {
    return agentSqlRpcFailureUserMessage(failure, l10n);
  }
  return failure.displayMessage;
}
