import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/agent_queries/data/agent_query_failure_ui_key_resolver.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_failure_message_for_ui_key.dart';
import 'package:colmeia/l10n/app_localizations.dart';

export 'package:colmeia/features/agent_queries/application/agent_query_failure_diagnostic.dart';

/// Technical details body with an explicit failure-class line for support.
///
/// When [l10n] is provided, the class line uses the same title mapping as
/// the agent-query failure presentation layer so transport vs query timeouts
/// are easy to distinguish in the attention panel and chart placeholders.
String agentQueryFailureTechnicalDetailsBody(
  AppFailure failure, {
  AppLocalizations? l10n,
}) {
  final uiKeyLine = _agentSqlFailureUiKeyDiagnosticLine(
    failure,
    l10n: l10n,
  );
  if (uiKeyLine == null) {
    return agentQueryFailureDiagnosticBody(failure);
  }
  return '$uiKeyLine\n${agentQueryFailureDiagnosticBody(failure)}';
}

String? _agentSqlFailureUiKeyDiagnosticLine(
  AppFailure failure, {
  AppLocalizations? l10n,
}) {
  final uiKey = resolveAgentQueryFailureUiKey(failure);
  if (uiKey == null || uiKey.isEmpty) {
    return null;
  }
  final label = l10n == null
      ? uiKey
      : agentSqlFailureTitleForUiKey(uiKey, l10n);
  return 'failureClass: $label (agentSqlRpcFailureUiKey=$uiKey)';
}
