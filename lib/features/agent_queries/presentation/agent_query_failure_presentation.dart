import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_sql_failure_message_for_ui_key.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';

enum AgentQueryFailureCategory {
  rateLimit,
  session,
  permission,
  validation,
  transient,
  cancelled,
  unknown,
}

/// Immutable view model for agent-query error surfaces.
class AgentQueryFailurePresentation {
  const AgentQueryFailurePresentation({
    required this.category,
    required this.title,
    required this.message,
    this.retryAfter,
    this.showRetry = true,
    this.showManageAgents = false,
    this.detailsBody,
    this.suppressPanel = false,
  });

  factory AgentQueryFailurePresentation.from(
    AppFailure failure,
    AppLocalizations l10n, {
    String? detailsBody,
  }) {
    if (shouldSuppressAgentQueryFailureUi(failure)) {
      return const AgentQueryFailurePresentation(
        category: AgentQueryFailureCategory.cancelled,
        title: '',
        message: '',
        suppressPanel: true,
      );
    }

    final category = _categoryFor(failure);
    final uiKey = _uiKeyFor(failure, category);
    final title = uiKey == null
        ? _fallbackTitle(category, l10n)
        : agentSqlFailureTitleForUiKey(uiKey, l10n);
    final message = agentQueryFailureUserMessage(failure, l10n);

    final resolvedDetails =
        detailsBody ?? agentQueryFailureDiagnosticBody(failure);

    return AgentQueryFailurePresentation(
      category: category,
      title: title,
      message: message,
      retryAfter: appFailureRetryAfter(failure),
      showRetry: category != AgentQueryFailureCategory.validation,
      showManageAgents: category == AgentQueryFailureCategory.session ||
          category == AgentQueryFailureCategory.permission,
      detailsBody: resolvedDetails,
    );
  }

  final AgentQueryFailureCategory category;
  final String title;
  final String message;
  final Duration? retryAfter;
  final bool showRetry;
  final bool showManageAgents;
  final String? detailsBody;
  final bool suppressPanel;

  AppInlinePanelTone get panelTone => switch (category) {
        AgentQueryFailureCategory.rateLimit ||
        AgentQueryFailureCategory.validation =>
          AppInlinePanelTone.informational,
        _ => AppInlinePanelTone.error,
      };

  static AgentQueryFailureCategory _categoryFor(AppFailure failure) {
    if (isAgentQueryRateLimitedFailure(failure)) {
      return AgentQueryFailureCategory.rateLimit;
    }
    if (failure is SessionFailure) {
      return AgentQueryFailureCategory.session;
    }
    if (failure is AuthorizationFailure) {
      return AgentQueryFailureCategory.permission;
    }
    if (failure is ValidationFailure) {
      return AgentQueryFailureCategory.validation;
    }
    if (failure is NetworkFailure || failure.isTransient) {
      return AgentQueryFailureCategory.transient;
    }
    return AgentQueryFailureCategory.unknown;
  }

  static String? _uiKeyFor(
    AppFailure failure,
    AgentQueryFailureCategory category,
  ) {
    final fromContext = failure.context[AgentSqlRpcFailureUiKey.field];
    if (fromContext is String && fromContext.isNotEmpty) {
      return fromContext;
    }
    return switch (category) {
      AgentQueryFailureCategory.rateLimit =>
        AgentSqlRpcFailureUiKey.rateLimited,
      AgentQueryFailureCategory.session =>
        AgentSqlRpcFailureUiKey.authenticationFailed,
      AgentQueryFailureCategory.permission =>
        AgentSqlRpcFailureUiKey.permissionDenied,
      AgentQueryFailureCategory.validation =>
        AgentSqlRpcFailureUiKey.sqlValidationFailed,
      AgentQueryFailureCategory.transient =>
        AgentSqlRpcFailureUiKey.networkError,
      _ => AgentSqlRpcFailureUiKey.generic,
    };
  }

  static String _fallbackTitle(
    AgentQueryFailureCategory category,
    AppLocalizations l10n,
  ) {
    return switch (category) {
      AgentQueryFailureCategory.rateLimit =>
        l10n.agentSqlFailureTitleRateLimited,
      AgentQueryFailureCategory.session =>
        l10n.agentSqlFailureTitleAuthenticationFailed,
      AgentQueryFailureCategory.permission =>
        l10n.agentSqlFailureTitlePermissionDenied,
      AgentQueryFailureCategory.validation =>
        l10n.agentSqlFailureTitleValidationFailed,
      AgentQueryFailureCategory.transient =>
        l10n.agentSqlFailureTitleNetworkError,
      _ => l10n.agentSqlFailureTitleGeneric,
    };
  }
}
