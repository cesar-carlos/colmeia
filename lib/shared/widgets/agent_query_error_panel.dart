import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_presentation.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_failure_technical_details.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

/// Shared inline error surface for agent SQL / bridge query failures.
class AgentQueryErrorPanel extends StatelessWidget {
  const AgentQueryErrorPanel({
    required this.presentation,
    super.key,
    this.onRetry,
    this.onShowDetails,
    this.detailsActionLabel,
    this.onManageAgents,
    this.retryCountdownLabel,
    this.variant = AppInlineErrorPanelVariant.card,
    this.belowMessage,
    this.showTechnicalDetails = true,
    this.supportContext,
    this.failure,
  });

  factory AgentQueryErrorPanel.fromFailure(
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
    return AgentQueryErrorPanel(
      presentation: AgentQueryFailurePresentation.from(
        failure,
        l10n,
        detailsBody: detailsBody,
      ),
      onRetry: onRetry,
      onShowDetails: onShowDetails,
      detailsActionLabel: detailsActionLabel,
      onManageAgents: onManageAgents,
      retryCountdownLabel: retryCountdownLabel,
      variant: variant,
      belowMessage: belowMessage,
      showTechnicalDetails: showTechnicalDetails,
      supportContext: supportContext,
      failure: failure,
    );
  }

  final AgentQueryFailurePresentation presentation;
  final VoidCallback? onRetry;
  final VoidCallback? onShowDetails;
  final String? detailsActionLabel;
  final VoidCallback? onManageAgents;
  final String? retryCountdownLabel;
  final AppInlineErrorPanelVariant variant;
  final Widget? belowMessage;
  final bool showTechnicalDetails;
  final AgentQueryFailureSupportContext? supportContext;
  final AppFailure? failure;

  @override
  Widget build(BuildContext context) {
    if (presentation.suppressPanel) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final onCooldown = retryCountdownLabel != null;
    final retryEnabled =
        presentation.showRetry && onRetry != null && !onCooldown;

    final technicalBody = presentation.detailsBody?.trim();
    final hasTechnical =
        showTechnicalDetails && technicalBody != null && technicalBody.isNotEmpty;

    final detailsLabel =
        detailsActionLabel ?? l10n.agentSqlFailureActionOpenFullDiagnostic;

    final secondaryActions = <Widget>[
      if (presentation.showManageAgents && onManageAgents != null)
        TextButton(
          onPressed: onManageAgents,
          child: Text(l10n.agentSqlFailureActionManageAgents),
        ),
      if (onShowDetails != null)
        TextButton(
          onPressed: onShowDetails,
          child: Text(detailsLabel),
        ),
    ];

    Widget? panelActions;
    if (presentation.showRetry && (onRetry != null || onCooldown)) {
      panelActions = Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          FilledButton(
            onPressed: retryEnabled ? onRetry : null,
            child: Text(
              onCooldown
                  ? retryCountdownLabel!
                  : l10n.appInlineErrorRetry,
            ),
          ),
          ...secondaryActions,
        ],
      );
    } else if (secondaryActions.isNotEmpty) {
      panelActions = Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: secondaryActions,
      );
    }

    final semanticsLabel = onCooldown
        ? '${presentation.title}. ${presentation.message}. $retryCountdownLabel'
        : '${presentation.title}. ${presentation.message}';

    Widget? technicalFooter;
    if (hasTechnical) {
      technicalFooter = AgentQueryFailureTechnicalDetails(
        body: technicalBody,
        failure: failure,
        supportContext: supportContext,
      );
    }

    return Semantics(
      label: semanticsLabel,
      child: AppInlineErrorPanel(
        title: presentation.title,
        message: presentation.message,
        tone: presentation.panelTone,
        variant: variant,
        belowMessage: belowMessage,
        onRetry: panelActions != null ? null : (retryEnabled ? onRetry : null),
        retryLabel: l10n.appInlineErrorRetry,
        actions: panelActions,
        footer: technicalFooter,
      ),
    );
  }
}
