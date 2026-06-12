import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/agent_query_chart_load_failure_message.dart';
import 'package:colmeia/features/agent_queries/data/agent_query_failure_ui_key_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/agent_query_failure_classification.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_failure_message_for_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_rpc_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';

export 'package:colmeia/features/agent_queries/domain/agent_query_failure_classification.dart'
    show isAgentQueryRateLimitedFailure, shouldSuppressAgentQueryFailureUi;

/// Localized user-facing text for agent SQL / bridge / transport failures.
///
/// Prefer this over [AppFailure.displayMessage] in UI that runs agent queries.
/// Returns `null` when the failure is a deliberate cancellation.
String? agentQueryFailureUserMessageOrNull(
  AppFailure failure,
  AppLocalizations l10n,
) {
  if (shouldSuppressAgentQueryFailureUi(failure)) {
    return null;
  }
  return agentQueryFailureUserMessage(failure, l10n);
}

/// Localized short title for agent-query error panels and overview load banners.
String agentQueryFailureTitle(AppFailure failure, AppLocalizations l10n) {
  final uiKey = agentQueryFailureResolvedUiKey(failure);
  return agentSqlFailureTitleForUiKey(uiKey, l10n);
}

/// Localized user-facing text for agent SQL / bridge / transport failures.
String agentQueryFailureUserMessage(AppFailure failure, AppLocalizations l10n) {
  if (failure is RpcFailure) {
    return _withRateLimitWait(
      agentSqlRpcFailureUserMessage(failure, l10n),
      failure,
      l10n,
    );
  }

  final uiKey = failure.context[AgentSqlRpcFailureUiKey.field] as String?;
  if (uiKey != null) {
    return _withRateLimitWait(
      agentSqlFailureMessageForUiKey(uiKey, l10n),
      failure,
      l10n,
    );
  }

  if (failure is SessionFailure) {
    return l10n.agentSqlErrorAuthenticationFailed;
  }
  if (failure is AuthorizationFailure) {
    return l10n.agentSqlErrorPermissionDenied;
  }
  if (isAgentQueryRateLimitedFailure(failure)) {
    return _rateLimitMessage(failure, l10n);
  }

  return failure.displayMessage;
}

/// Chart / inline surfaces: prefer [loadFailure], then legacy cached string.
String chartAgentQueryLoadFailureMessage({
  required AppLocalizations l10n,
  required String genericFallback,
  AppFailure? loadFailure,
  String? legacyMessage,
}) {
  return resolveAgentQueryChartLoadFailureMessage(
    genericFallback: genericFallback,
    loadFailure: loadFailure,
    legacyMessage: legacyMessage,
    localizedFailureMessage: (failure) =>
        agentQueryFailureUserMessageOrNull(failure, l10n),
  );
}

String _withRateLimitWait(
  String base,
  AppFailure failure,
  AppLocalizations l10n,
) {
  if (!isAgentQueryRateLimitedFailure(failure)) {
    return base;
  }
  return _rateLimitMessage(failure, l10n);
}

String _rateLimitMessage(AppFailure failure, AppLocalizations l10n) {
  final retryAfter = appFailureRetryAfter(failure);
  if (retryAfter == null) {
    return l10n.agentSqlErrorRateLimited;
  }
  final seconds = _rateLimitWaitSeconds(retryAfter);
  if (seconds <= 0) {
    return l10n.agentSqlErrorRateLimited;
  }
  return l10n.agentSqlErrorRateLimitedWithWait(seconds);
}

int _rateLimitWaitSeconds(Duration retryAfter) {
  final seconds = retryAfter.inSeconds;
  if (seconds > 0) {
    return seconds;
  }
  final ms = retryAfter.inMilliseconds;
  return ms <= 0 ? 0 : 1;
}
