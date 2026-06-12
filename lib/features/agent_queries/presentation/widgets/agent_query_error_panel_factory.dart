import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_presentation.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_failure_technical_details.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/agent_query_error_panel.dart';
import 'package:colmeia/shared/widgets/agent_query_error_presentation.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

/// Feature-layer factory for agent-query error panels.
abstract final class AgentQueryErrorPanelFactory {
  static AgentQueryErrorPanel fromFailure(
    AppFailure failure,
    AppLocalizations l10n, {
    String? detailsBody,
    VoidCallback? onRetry,
    VoidCallback? onShowDetails,
    String? detailsActionLabel,
    VoidCallback? onManageAgents,
    String? retryCountdownLabel,
    AppInlineErrorPanelVariant variant = AppInlineErrorPanelVariant.card,
    Widget? belowMessage,
    bool showTechnicalDetails = true,
    AgentQueryFailureSupportContext? supportContext,
  }) {
    final featurePresentation = AgentQueryFailurePresentation.from(
      failure,
      l10n,
      detailsBody: detailsBody,
    );

    final technicalBody = featurePresentation.detailsBody?.trim();
    final hasTechnical =
        showTechnicalDetails &&
        technicalBody != null &&
        technicalBody.isNotEmpty;

    return AgentQueryErrorPanel(
      presentation: AgentQueryErrorPresentation(
        title: featurePresentation.title,
        message: featurePresentation.message,
        panelTone: featurePresentation.panelTone,
        showRetry: featurePresentation.showRetry,
        showManageAgents: featurePresentation.showManageAgents,
        suppressPanel: featurePresentation.suppressPanel,
        detailsBody: featurePresentation.detailsBody,
      ),
      onRetry: onRetry,
      onShowDetails: onShowDetails,
      detailsActionLabel: detailsActionLabel,
      onManageAgents: onManageAgents,
      retryCountdownLabel: retryCountdownLabel,
      variant: variant,
      belowMessage: belowMessage,
      technicalFooter: hasTechnical
          ? AgentQueryFailureTechnicalDetails(
              body: technicalBody,
              failure: failure,
              supportContext: supportContext,
            )
          : null,
    );
  }
}
