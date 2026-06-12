import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/overview/application/overview_app_failure_diagnostic.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';

/// Discriminator used by the alerts widget to wire the right callbacks
/// (retry, open agents, open partial-failure sheet, plain-detail sheet).
enum OverviewAlertKind {
  loadError,
  setupRequired,
  missingClientToken,
  agentsOffline,
  partialAgentQueries,
  multiAgentAggregation,
}

/// Normalized references for a list of affected agents that can be opened in
/// a "view affected" bottom sheet.
class OverviewAlertAffectedAgents {
  const OverviewAlertAffectedAgents({
    required this.normalizedNames,
    required this.sheetTitle,
  });

  final List<String> normalizedNames;
  final String sheetTitle;
}

/// Pure data description of a single home alert banner. Built from the
/// `Overview` snapshot + transient retry state and then rendered by the
/// `OverviewHomeAlertsSection` widget. Keeping this as a value object
/// makes the banner derivation rules unit-testable in isolation.
///
/// Spec carries only kind-specific overrides. Shared defaults (details
/// button label and semantics, retry label, "manage agents" label) are
/// applied by the renderer using [AppLocalizations] so this object stays
/// focused on what differs per banner.
class OverviewAlertBannerSpec {
  const OverviewAlertBannerSpec({
    required this.kind,
    required this.tone,
    required this.title,
    required this.message,
    this.detailsBody,
    this.affectedAgents,
    this.showRetry = false,
    this.showManage = false,
    this.primaryLabel,
    this.retryDisabledLabel,
  });

  final OverviewAlertKind kind;
  final AppInlinePanelTone tone;
  final String title;
  final String message;

  /// Plain-text body used by the default "show details" sheet for this
  /// banner. When null, the widget may still open a richer sheet (e.g.
  /// partial-failure details from `Overview.partialQueryFailureDetails`).
  final String? detailsBody;

  /// Optional affected-agents link rendered below the message.
  final OverviewAlertAffectedAgents? affectedAgents;

  final bool showRetry;
  final bool showManage;

  /// Overrides the default primary CTA label. When null, the widget falls
  /// back to the retry or "manage agents" label depending on which action
  /// is enabled.
  final String? primaryLabel;

  /// Disabled-state label for the retry button while a `Retry-After` window
  /// is open. When non-null the renderer always shows the disabled state
  /// (even when [showRetry] is true).
  final String? retryDisabledLabel;
}

/// Builds the ordered list of banners that should be rendered on the home
/// alerts section. Pure function: no `BuildContext` and no side effects.
List<OverviewAlertBannerSpec> buildOverviewAlertBannerSpecs({
  required AppLocalizations l10n,
  required String? errorMessage,
  required String? errorDiagnosticBody,
  required Overview? overview,
  required List<String> missingTokenAgentNames,
  required List<String> partialFailureAgentNames,
  required List<String> skippedDueToHubPresenceAgentNames,
  required String? retryCountdownLabel,
  AppFailure? loadFailure,
}) {
  final specs = <OverviewAlertBannerSpec>[];

  if (errorMessage != null) {
    final technicalBody = loadFailure != null
        ? overviewAppFailureDiagnosticBody(
            loadFailure,
            localizedUserMessage: errorMessage,
          )
        : errorDiagnosticBody;
    specs.add(
      OverviewAlertBannerSpec(
        kind: OverviewAlertKind.loadError,
        tone: AppInlinePanelTone.error,
        title: _overviewLoadErrorTitle(l10n, loadFailure),
        message: errorMessage,
        detailsBody: _composeLoadErrorBody(errorMessage, technicalBody),
        showRetry: true,
        showManage: true,
        retryDisabledLabel: retryCountdownLabel,
      ),
    );
  }

  final o = overview;
  if (o != null && o.requiresClientTokenSetup) {
    specs.add(
      OverviewAlertBannerSpec(
        kind: OverviewAlertKind.setupRequired,
        tone: AppInlinePanelTone.informational,
        title: l10n.dashboardSetupRequiredTitle,
        message: l10n.dashboardSetupRequiredMessage,
        detailsBody: _composeBodyWithAgents(
          l10n.dashboardSetupRequiredMessage,
          missingTokenAgentNames,
        ),
        affectedAgents: missingTokenAgentNames.isEmpty
            ? null
            : OverviewAlertAffectedAgents(
                normalizedNames: missingTokenAgentNames,
                sheetTitle: l10n.dashboardAffectedAgentsSheetTitleSetupRequired,
              ),
        showManage: true,
        primaryLabel: l10n.overviewHomeManageBranchesAction,
      ),
    );
  }

  if (o != null && o.hasMissingClientToken && !o.requiresClientTokenSetup) {
    specs.add(
      OverviewAlertBannerSpec(
        kind: OverviewAlertKind.missingClientToken,
        tone: AppInlinePanelTone.informational,
        title: l10n.dashboardMissingClientTokenTitle,
        message: l10n.dashboardMissingClientTokenMessage,
        detailsBody: _composeBodyWithAgents(
          l10n.dashboardMissingClientTokenMessage,
          missingTokenAgentNames,
        ),
        affectedAgents: missingTokenAgentNames.isEmpty
            ? null
            : OverviewAlertAffectedAgents(
                normalizedNames: missingTokenAgentNames,
                sheetTitle: l10n.dashboardAffectedAgentsSheetTitleMissingToken,
              ),
        showManage: true,
        primaryLabel: l10n.overviewHomeManageBranchesAction,
      ),
    );
  }

  if (o != null && o.hasAgentsSkippedDueToHubPresence) {
    specs.add(
      OverviewAlertBannerSpec(
        kind: OverviewAlertKind.agentsOffline,
        tone: AppInlinePanelTone.informational,
        title: l10n.dashboardAgentsOfflineTitle,
        message: l10n.dashboardAgentsOfflineMessage,
        detailsBody: _composeBodyWithAgents(
          l10n.dashboardAgentsOfflineMessage,
          skippedDueToHubPresenceAgentNames,
        ),
        affectedAgents: skippedDueToHubPresenceAgentNames.isEmpty
            ? null
            : OverviewAlertAffectedAgents(
                normalizedNames: skippedDueToHubPresenceAgentNames,
                sheetTitle: l10n.dashboardAffectedAgentsSheetTitleOffline,
              ),
        showRetry: true,
        showManage: true,
      ),
    );
  }

  if (o != null &&
      (o.hasPartialAgentQueryFailure || o.hasLucratividadePartialFailure)) {
    specs.add(
      OverviewAlertBannerSpec(
        kind: OverviewAlertKind.partialAgentQueries,
        tone: AppInlinePanelTone.informational,
        title: l10n.dashboardPartialAgentQueriesTitle,
        message: l10n.dashboardPartialAgentQueriesMessage,
        detailsBody: _composeBodyWithAgents(
          l10n.dashboardPartialAgentQueriesMessage,
          partialFailureAgentNames,
        ),
        affectedAgents: partialFailureAgentNames.isEmpty
            ? null
            : OverviewAlertAffectedAgents(
                normalizedNames: partialFailureAgentNames,
                sheetTitle:
                    l10n.dashboardAffectedAgentsSheetTitlePartialFailure,
              ),
        showRetry: true,
        showManage: true,
      ),
    );
  }

  if (o != null && o.shouldShowMultiAgentAggregationNote) {
    specs.add(
      OverviewAlertBannerSpec(
        kind: OverviewAlertKind.multiAgentAggregation,
        tone: AppInlinePanelTone.informational,
        title: l10n.dashboardMultiAgentAggregationTitle,
        message: l10n.dashboardMultiAgentAggregationMessage,
      ),
    );
  }

  return specs;
}

String _composeLoadErrorBody(String message, String? diagnostic) {
  final d = diagnostic?.trim();
  if (d == null || d.isEmpty) {
    return message;
  }
  return '$message\n\n$d';
}

String _overviewLoadErrorTitle(AppLocalizations l10n, AppFailure? loadFailure) {
  if (loadFailure == null) {
    return l10n.overviewLoadErrorTitle;
  }
  if (loadFailure.context[OverviewFailureUiKey.field] != null) {
    return l10n.overviewLoadErrorTitle;
  }
  return agentQueryFailureTitle(loadFailure, l10n);
}

String _composeBodyWithAgents(String message, List<String> names) {
  if (names.isEmpty) {
    return message;
  }
  final bullets = names.map((n) => '- $n').join('\n');
  return '$message\n\n$bullets';
}
