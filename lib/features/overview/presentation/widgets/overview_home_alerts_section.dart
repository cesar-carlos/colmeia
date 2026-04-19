import 'dart:async';

import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_agent_names_list_sheet.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_panel_actions.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_text_action_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:flutter/material.dart';

/// Single surface for overview banners: same logical order as the previous
/// stacked [AppInlineErrorPanel] list.
class OverviewHomeAlertsSection extends StatelessWidget {
  const OverviewHomeAlertsSection({
    required this.l10n,
    required this.errorMessage,
    required this.overview,
    required this.missingTokenAgentNamesNormalized,
    required this.partialFailureAgentNamesNormalized,
    required this.onOpenAgents,
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
  final VoidCallback? onRetryOverview;

  /// Label rendered on the "Retry" button while the overview controller
  /// is throttled by a server `Retry-After` hint. When non-null the
  /// button is shown as disabled regardless of [onRetryOverview].
  final String? retryCountdownLabel;

  bool get _hasAnyBanner {
    if (errorMessage != null) return true;
    final o = overview;
    if (o == null) return false;
    if (o.requiresClientTokenSetup) return true;
    if (o.isStaleCache) return true;
    if (o.hasMissingClientToken && !o.requiresClientTokenSetup) return true;
    if (o.hasPartialAgentQueryFailure) return true;
    if (o.shouldShowMultiAgentAggregationNote) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyBanner) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final sheetTitlePartialFailure =
        l10n.dashboardAffectedAgentsSheetTitlePartialFailure;
    final sheetTitleMissingToken =
        l10n.dashboardAffectedAgentsSheetTitleMissingToken;
    final sheetTitleSetupRequired =
        l10n.dashboardAffectedAgentsSheetTitleSetupRequired;

    final children = <Widget>[];

    void gapIfNeeded() {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: tokens.gapMd));
      }
    }

    if (errorMessage case final String msg) {
      gapIfNeeded();
      children.add(
        AppInlineErrorPanel(
          title: l10n.overviewLoadErrorTitle,
          message: msg,
          actions: OverviewPanelActions(
            onRetry: onRetryOverview,
            onManageAgents: onOpenAgents,
            retryLabel: l10n.appInlineErrorRetry,
            // Render the button as disabled with a countdown while the
            // controller's `RetryAfterGate` is closed. The callback
            // itself is also no-op'd by the controller — this is the
            // visible feedback so the user understands why.
            retryDisabledLabel: retryCountdownLabel,
            manageAgentsLabel: l10n.clientAgentsPageTitle,
          ),
        ),
      );
    }

    final o = overview;
    if (o != null && o.requiresClientTokenSetup) {
      gapIfNeeded();
      children.add(
        AppInlineErrorPanel(
          tone: AppInlinePanelTone.informational,
          title: l10n.dashboardSetupRequiredTitle,
          message: l10n.dashboardSetupRequiredMessage,
          belowMessage: missingTokenAgentNamesNormalized.isEmpty
              ? null
              : _OverviewAffectedAgentsListLink(
                  l10n: l10n,
                  normalizedNames: missingTokenAgentNamesNormalized,
                  sheetTitle: sheetTitleSetupRequired,
                ),
          actions: OverviewPanelActions(
            onManageAgents: onOpenAgents,
            primaryLabel: l10n.clientAgentsPageTitle,
            manageAgentsLabel: l10n.clientAgentsPageTitle,
          ),
        ),
      );
    }

    if (o?.isStaleCache == true) {
      gapIfNeeded();
      children.add(
        AppInlineErrorPanel(
          tone: AppInlinePanelTone.informational,
          title: l10n.overviewStaleCacheTitle,
          message: l10n.overviewStaleCacheMessage,
          actions: OverviewPanelActions(
            onRetry: onRetryOverview,
            onManageAgents: o?.hasMissingClientToken == true
                ? onOpenAgents
                : null,
            retryLabel: l10n.appInlineErrorRetry,
            manageAgentsLabel: l10n.clientAgentsPageTitle,
          ),
        ),
      );
    }

    if (o != null && o.hasMissingClientToken && !o.requiresClientTokenSetup) {
      gapIfNeeded();
      children.add(
        AppInlineErrorPanel(
          tone: AppInlinePanelTone.informational,
          title: l10n.dashboardMissingClientTokenTitle,
          message: l10n.dashboardMissingClientTokenMessage,
          belowMessage: missingTokenAgentNamesNormalized.isEmpty
              ? null
              : _OverviewAffectedAgentsListLink(
                  l10n: l10n,
                  normalizedNames: missingTokenAgentNamesNormalized,
                  sheetTitle: sheetTitleMissingToken,
                ),
          actions: OverviewPanelActions(
            onManageAgents: onOpenAgents,
            primaryLabel: l10n.clientAgentsPageTitle,
            manageAgentsLabel: l10n.clientAgentsPageTitle,
          ),
        ),
      );
    }

    if (o != null && o.hasPartialAgentQueryFailure) {
      gapIfNeeded();
      children.add(
        AppInlineErrorPanel(
          tone: AppInlinePanelTone.informational,
          title: l10n.dashboardPartialAgentQueriesTitle,
          message: l10n.dashboardPartialAgentQueriesMessage,
          belowMessage: partialFailureAgentNamesNormalized.isEmpty
              ? null
              : _OverviewAffectedAgentsListLink(
                  l10n: l10n,
                  normalizedNames: partialFailureAgentNamesNormalized,
                  sheetTitle: sheetTitlePartialFailure,
                ),
          actions: OverviewPanelActions(
            onRetry: onRetryOverview,
            onManageAgents: onOpenAgents,
            retryLabel: l10n.appInlineErrorRetry,
            manageAgentsLabel: l10n.clientAgentsPageTitle,
          ),
        ),
      );
    }

    if (o != null && o.shouldShowMultiAgentAggregationNote) {
      gapIfNeeded();
      children.add(
        AppInlineErrorPanel(
          tone: AppInlinePanelTone.informational,
          title: l10n.dashboardMultiAgentAggregationTitle,
          message: l10n.dashboardMultiAgentAggregationMessage,
        ),
      );
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
