import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_failure_message_for_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_rpc_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';

/// Whether [failure] should surface agent-query rate-limit copy (RPC, socket,
/// REST 429 on commands).
bool isAgentQueryRateLimitedFailure(AppFailure failure) {
  if (failure.context[AgentSqlRpcFailureUiKey.field] ==
      AgentSqlRpcFailureUiKey.rateLimited) {
    return true;
  }
  final transportCode =
      failure.context[AgentQueriesFailureContext.transportCodeField];
  if (transportCode is String && isSocketRateLimitedCode(transportCode)) {
    return true;
  }
  if (failure is RpcFailure && failure.rpcCode == -32013) {
    return true;
  }
  return false;
}

/// True when UI should not show an error surface (navigation away / cancel).
bool shouldSuppressAgentQueryFailureUi(AppFailure failure) {
  if (isCancelledAgentQueryFailure(failure.context)) {
    return true;
  }
  if (failure is OperationCancelledFailure) {
    return true;
  }
  final uiKey = failure.context[AgentSqlRpcFailureUiKey.field];
  return uiKey == AgentSqlRpcFailureUiKey.executionCancelled;
}

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
  required String genericFallback, AppFailure? loadFailure,
  String? legacyMessage,
}) {
  if (loadFailure != null) {
    final localized = agentQueryFailureUserMessageOrNull(loadFailure, l10n);
    if (localized != null && localized.trim().isNotEmpty) {
      return localized;
    }
  }
  final legacy = legacyMessage?.trim();
  if (legacy != null && legacy.isNotEmpty) {
    return legacy;
  }
  return genericFallback;
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
