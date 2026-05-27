import 'dart:async';

import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/presentation/overview_alert_banner_spec.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_agent_names_list_sheet.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_alert_detail_sheet.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_panel_actions.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_text_action_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:flutter/material.dart';

/// Single surface for overview banners: derives a declarative list of specs
/// from the overview/error state, then renders one `AppInlineErrorPanel`
/// per spec. Banner derivation lives in
/// [buildOverviewAlertBannerSpecs] for unit-testability.
class OverviewHomeAlertsSection extends StatelessWidget {
  const OverviewHomeAlertsSection({
    required this.l10n,
    required this.errorMessage,
    required this.overview,
    required this.missingTokenAgentNamesNormalized,
    required this.partialFailureAgentNamesNormalized,
    required this.onOpenAgents,
    this.errorDiagnosticBody,
    this.skippedDueToHubPresenceAgentNamesNormalized = const <String>[],
    this.onRetryOverview,
    this.retryCountdownLabel,
    super.key,
  });

  final AppLocalizations l10n;
  final String? errorMessage;
  final Overview? overview;
  final List<String> missingTokenAgentNamesNormalized;
  final List<String> partialFailureAgentNamesNormalized;
  final VoidCallback onOpenAgents;
  final String? errorDiagnosticBody;

  /// Display names for the dedicated "agentes offline" banner — agents
  /// that DO have a stored client_token but were skipped at dispatch
  /// because the hub-presence policy marked them as disconnected.
  /// Default empty so legacy call sites keep compiling; the banner is
  /// only rendered when this list is non-empty AND the underlying
  /// [Overview.hasAgentsSkippedDueToHubPresence] flag is true.
  final List<String> skippedDueToHubPresenceAgentNamesNormalized;
  final VoidCallback? onRetryOverview;

  /// Label rendered on the "Retry" button while the overview controller
  /// is throttled by a server `Retry-After` hint. When non-null the
  /// button is shown as disabled regardless of [onRetryOverview].
  final String? retryCountdownLabel;

  @override
  Widget build(BuildContext context) {
    final specs = buildOverviewAlertBannerSpecs(
      l10n: l10n,
      errorMessage: errorMessage,
      errorDiagnosticBody: errorDiagnosticBody,
      overview: overview,
      missingTokenAgentNames: missingTokenAgentNamesNormalized,
      partialFailureAgentNames: partialFailureAgentNamesNormalized,
      skippedDueToHubPresenceAgentNames:
          skippedDueToHubPresenceAgentNamesNormalized,
      retryCountdownLabel: retryCountdownLabel,
    );

    if (specs.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    final children = <Widget>[];
    for (var i = 0; i < specs.length; i++) {
      if (i > 0) {
        children.add(SizedBox(height: tokens.gapMd));
      }
      children.add(_OverviewAlertBanner(spec: specs[i], host: this));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: tokens.gapMd),
        Semantics(
          liveRegion: true,
          child: AppSectionCardWithHeading(
            title: l10n.overviewHomeAlertsSectionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders one banner from its spec, wiring context-bound callbacks
/// (retry / open agents / open details) by inspecting the spec kind.
class _OverviewAlertBanner extends StatelessWidget {
  const _OverviewAlertBanner({
    required this.spec,
    required this.host,
  });

  final OverviewAlertBannerSpec spec;
  final OverviewHomeAlertsSection host;

  VoidCallback? _resolveOnShowDetails(BuildContext context) {
    final detailsBody = spec.detailsBody;
    if (detailsBody == null) {
      // The multi-agent aggregation banner has no details sheet.
      return null;
    }
    if (spec.kind == OverviewAlertKind.partialAgentQueries) {
      final overview = host.overview;
      final details = overview?.partialQueryFailureDetails ?? const [];
      if (details.isNotEmpty) {
        return () => unawaited(
              showOverviewPartialFailureDetailsSheet(
                context: context,
                l10n: host.l10n,
                details: details,
              ),
            );
      }
    }
    return () => unawaited(
          showOverviewAlertPlainDetailSheet(
            context: context,
            title: _detailsSheetTitle(),
            body: detailsBody,
          ),
        );
  }

  String _detailsSheetTitle() {
    return spec.affectedAgents?.sheetTitle ?? spec.title;
  }

  @override
  Widget build(BuildContext context) {
    final affected = spec.affectedAgents;
    final l10n = host.l10n;
    return AppInlineErrorPanel(
      tone: spec.tone,
      title: spec.title,
      message: spec.message,
      belowMessage: affected == null
          ? null
          : _OverviewAffectedAgentsListLink(
              l10n: l10n,
              normalizedNames: affected.normalizedNames,
              sheetTitle: affected.sheetTitle,
            ),
      actions: _hasAnyAction
          ? OverviewPanelActions(
              onRetry: spec.showRetry ? host.onRetryOverview : null,
              onManageAgents: spec.showManage ? host.onOpenAgents : null,
              onShowDetails: _resolveOnShowDetails(context),
              detailsLabel: l10n.overviewHomeAlertErrorDetailsButton,
              detailsSemanticsLabel:
                  l10n.overviewHomeAlertErrorDetailsSemanticsLabel,
              retryLabel: l10n.appInlineErrorRetry,
              retryDisabledLabel: spec.retryDisabledLabel,
              primaryLabel: spec.primaryLabel,
              manageAgentsLabel: l10n.overviewHomeManageBranchesAction,
            )
          : null,
    );
  }

  bool get _hasAnyAction =>
      spec.showRetry || spec.showManage || spec.detailsBody != null;
}

class _OverviewAffectedAgentsListLink extends StatelessWidget {
  const _OverviewAffectedAgentsListLink({
    required this.l10n,
    required this.normalizedNames,
    required this.sheetTitle,
  });

  final AppLocalizations l10n;
  final List<String> normalizedNames;
  final String sheetTitle;

  @override
  Widget build(BuildContext context) {
    final count = normalizedNames.length;
    final label = l10n.dashboardViewAffectedAgentsList(count);
    return Align(
      alignment: Alignment.centerLeft,
      child: AppTextActionButton(
        label: label,
        semanticsLabel: '$label. $sheetTitle',
        onPressed: () => unawaited(
          showOverviewAgentNamesListSheet(
            context: context,
            title: sheetTitle,
            normalizedAgentNames: normalizedNames,
          ),
        ),
      ),
    );
  }
}
