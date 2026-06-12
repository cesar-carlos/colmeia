import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_error_panel_factory.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/agent_query_error_panel.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:flutter/material.dart';

/// Inline error for agent-query loads: [AgentQueryErrorPanel] when [loadFailure]
/// is set, otherwise legacy [AppInlineErrorPanel] from [errorMessage].
class AgentQueryLoadErrorSurface extends StatelessWidget {
  const AgentQueryLoadErrorSurface({
    super.key,
    this.loadFailure,
    this.errorMessage,
    this.onRetry,
    this.retryCountdownLabel,
    this.supportContext,
    this.variant = AppInlineErrorPanelVariant.card,
    this.legacyTitle,
    this.legacyTone = AppInlinePanelTone.error,
    this.belowMessage,
    this.actions,
    this.showTechnicalDetails = true,
  });

  final AppFailure? loadFailure;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? retryCountdownLabel;
  final AgentQueryFailureSupportContext? supportContext;
  final AppInlineErrorPanelVariant variant;
  final String? legacyTitle;
  final AppInlinePanelTone legacyTone;
  final Widget? belowMessage;
  final Widget? actions;
  final bool showTechnicalDetails;

  bool get hasError => hasErrorFor(
    loadFailure: loadFailure,
    errorMessage: errorMessage,
  );

  static bool hasErrorFor({
    AppFailure? loadFailure,
    String? errorMessage,
  }) {
    if (loadFailure != null) {
      return true;
    }
    final message = errorMessage?.trim();
    return message != null && message.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasError) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final failure = loadFailure;
    if (failure != null) {
      return AgentQueryErrorPanelFactory.fromFailure(
        failure,
        l10n,
        onRetry: onRetry,
        retryCountdownLabel: retryCountdownLabel,
        variant: variant,
        belowMessage: belowMessage,
        showTechnicalDetails: showTechnicalDetails,
        supportContext: supportContext,
      );
    }

    return AppInlineErrorPanel(
      title: legacyTitle,
      message: errorMessage!.trim(),
      tone: legacyTone,
      variant: variant,
      belowMessage: belowMessage,
      onRetry: actions == null ? onRetry : null,
      actions: actions,
    );
  }
}
