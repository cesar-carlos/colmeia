import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/agent_query_error_presentation.dart';
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
    this.technicalFooter,
  });

  final AgentQueryErrorPresentation presentation;
  final VoidCallback? onRetry;
  final VoidCallback? onShowDetails;
  final String? detailsActionLabel;
  final VoidCallback? onManageAgents;
  final String? retryCountdownLabel;
  final AppInlineErrorPanelVariant variant;
  final Widget? belowMessage;
  final Widget? technicalFooter;

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
              onCooldown ? retryCountdownLabel! : l10n.appInlineErrorRetry,
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
