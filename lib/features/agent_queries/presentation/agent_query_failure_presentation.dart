import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
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
    final title = agentQueryFailureTitle(failure, l10n);
    final message = agentQueryFailureUserMessage(failure, l10n);

    final resolvedDetails = detailsBody ??
        agentQueryFailureTechnicalDetailsBody(
          failure,
          l10n: l10n,
        );

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

}
