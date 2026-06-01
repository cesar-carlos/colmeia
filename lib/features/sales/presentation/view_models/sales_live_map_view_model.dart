import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/refresh/auto_refresh_ui_state.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_filter_summary.dart';

/// Mapped branch count above which the live map auto-downgrades the user's
/// chosen `branches` detail level to `municipalities` to keep the map
/// readable.
const int kSalesLiveMapAutoMunicipalityDetailPointThreshold = 200;

class SalesLiveMapViewModel {
  SalesLiveMapViewModel._({
    required this.agentsSummary,
    required this.periodSummary,
    required this.detailSummary,
    required this.visualSummary,
    required this.usesMapLabel,
    required this.mapSubtitle,
    required this.loadErrorMessage,
    required this.fullscreenFilterSummary,
  });

  factory SalesLiveMapViewModel.fromState(
    SalesLiveMapPresentationState state,
    AppLocalizations l10n,
  ) {
    final periodSummary = _periodSummary(state.filter, l10n);
    final detailSummary = _detailLabel(state.filter.detailLevel, l10n);
    final visual = state.filter.detailLevel == SalesLiveMapMapDetail.states
        ? SalesLiveMapMarkerVisual.bubble
        : state.filter.markerVisual;
    final usesMapLabel =
        state.filter.detailLevel == SalesLiveMapMapDetail.states;
    final visualSummary = _visualLabel(visual, l10n);
    final agentsSummary = _agentsSummary(state, l10n);
    final mapSubtitle = _mapSubtitle(state, l10n);
    final loadErrorMessage = _loadErrorMessage(state, l10n);
    final filterParts = <String>[
      '${l10n.salesLiveMapAgentsLabel}: $agentsSummary',
      '${l10n.salesLiveMapPeriodLabel}: $periodSummary',
      '${l10n.salesLiveMapDetailLabel}: $detailSummary',
      '${usesMapLabel ? l10n.salesLiveMapMapLabel : l10n.salesLiveMapVisualLabel}: $visualSummary',
    ];

    return SalesLiveMapViewModel._(
      agentsSummary: agentsSummary,
      periodSummary: periodSummary,
      detailSummary: detailSummary,
      visualSummary: visualSummary,
      usesMapLabel: usesMapLabel,
      mapSubtitle: mapSubtitle,
      loadErrorMessage: loadErrorMessage,
      fullscreenFilterSummary: filterParts.join(
        AppChartFilterSummary.spacedMiddleDotSeparator,
      ),
    );
  }

  final String agentsSummary;
  final String periodSummary;
  final String detailSummary;
  final String visualSummary;
  final bool usesMapLabel;
  final String mapSubtitle;
  final String loadErrorMessage;
  final String fullscreenFilterSummary;

  /// Resolves the auto-refresh pause reason from the current presentation
  /// state. Returns `null` when scheduling can proceed normally.
  static AutoRefreshPauseReason? resolveAutoRefreshPauseReason(
    SalesLiveMapPresentationState state,
  ) {
    if (state.isLoading) {
      return AutoRefreshPauseReason.pageLoading;
    }
    final availableAgents = state.availableAgents;
    if (availableAgents.isEmpty) {
      return AutoRefreshPauseReason.noEligibleSelection;
    }
    final tokenBackedAgentIds = state.tokenBackedAgentIds;
    if (tokenBackedAgentIds.isEmpty) {
      return AutoRefreshPauseReason.missingLocalToken;
    }
    final selectedAgentIds = state.filter.selectedAgentIds;
    if (selectedAgentIds == null) {
      return null;
    }
    if (selectedAgentIds.any(tokenBackedAgentIds.contains)) {
      return null;
    }
    final selectedSet = selectedAgentIds.toSet();
    final selectedAgents = availableAgents
        .where((agent) => selectedSet.contains(agent.agentId))
        .toList(growable: false);
    if (selectedAgents.isNotEmpty &&
        selectedAgents.every((agent) => agent.missingLocalClientToken)) {
      return AutoRefreshPauseReason.missingLocalToken;
    }
    return AutoRefreshPauseReason.noEligibleSelection;
  }

  /// Timestamp of the latest successful load embedded in [state], or `null`
  /// when there is no such reload to record yet.
  static DateTime? resolveSuccessfulRefreshAt(
    SalesLiveMapPresentationState state,
  ) {
    final result = state.result;
    if (result == null ||
        result.loadFailed ||
        result.cancelled ||
        result.salesDataPending ||
        state.isLoading) {
      return null;
    }
    return result.refreshedAt;
  }

  /// True when at least one of the available agents has a local client token
  /// and the current selection includes at least one of those agents.
  ///
  /// Equivalent to the previous `state.canScheduleAutoRefresh` getter; kept
  /// here so product rules live in the view model instead of the state.
  static bool canScheduleAutoRefresh(SalesLiveMapPresentationState state) {
    final tokenBacked = state.tokenBackedAgentIds;
    if (tokenBacked.isEmpty) {
      return false;
    }
    final selected = state.filter.selectedAgentIds;
    if (selected == null) {
      return true;
    }
    return selected.any(tokenBacked.contains);
  }

  /// True when the current result is loaded successfully but has no rows to
  /// show — the empty notice should be displayed instead of a chart.
  static bool shouldShowEmptyNotice(SalesLiveMapPresentationState state) {
    final currentResult = state.result;
    if (currentResult == null ||
        currentResult.salesDataPending ||
        currentResult.loadFailed ||
        currentResult.hasPartialIssue) {
      return false;
    }
    return currentResult.totalSalesCount == 0 ||
        currentResult.totalBranchCount == 0;
  }

  /// Effective detail level after applying the auto-downgrade policy: when
  /// the user picked `branches` but the result has too many mapped branches,
  /// fall back to `municipalities` to keep the map readable.
  static SalesLiveMapMapDetail effectiveDetailLevel(
    SalesLiveMapPresentationState state,
  ) {
    final currentResult = state.result;
    if (state.filter.detailLevel == SalesLiveMapMapDetail.branches &&
        (currentResult?.mappedBranchCount ?? 0) >
            kSalesLiveMapAutoMunicipalityDetailPointThreshold) {
      return SalesLiveMapMapDetail.municipalities;
    }
    return state.filter.detailLevel;
  }

  /// Visual spec to render the operational map for the given state, taking
  /// the auto-downgrade policy into account (see [effectiveDetailLevel]).
  static SalesLiveMapVisualSpec visualSpec(
    SalesLiveMapPresentationState state,
  ) {
    return SalesLiveMapVisualSpec.operational(
      detailLevel: effectiveDetailLevel(state),
      markerVisual: state.filter.markerVisual,
    );
  }

  /// Localized messages displayed inside the attention panel when the live
  /// map load reports any partial issue. Order matters: the summary line
  /// always comes first, followed by issue-specific lines.
  static List<String> attentionMessages(
    SalesLiveMapLoadResult result,
    AppLocalizations l10n,
  ) {
    return <String>[
      l10n.salesLiveMapAgentQuerySummary(
        result.plannedAgentCount,
        result.queriedAgentCount,
        result.salesAgentCount,
        result.noSalesAgentOptions.length,
      ),
      if (result.failedAgentCount > 0)
        l10n.salesLiveMapPartialFailedAgents(result.failedAgentCount),
      if (result.missingClientTokenAgentCount > 0)
        l10n.salesLiveMapPartialMissingTokenAgents(
          result.missingClientTokenAgentCount,
        ),
      if (result.skippedOfflineAgentCount > 0)
        l10n.salesLiveMapPartialOfflineAgents(
          result.skippedOfflineAgentCount,
        ),
      if (result.rowCapReachedAgentCount > 0)
        l10n.salesLiveMapPartialRowCapReached(
          result.rowCapReachedAgentCount,
        ),
      if (result.mappedBranchCount < result.totalBranchCount)
        l10n.salesLiveMapPartialMissingCoordinates(
          result.totalBranchCount - result.mappedBranchCount,
        ),
      if (result.noSalesAgentOptions.isNotEmpty)
        l10n.salesLiveMapPartialNoSalesAgents(
          result.noSalesAgentOptions.length,
        ),
      if (result.noSalesBranchCount > 0)
        l10n.salesLiveMapPartialZeroedBranches(result.noSalesBranchCount),
      if (result.salesUnavailableBranchCount > 0)
        l10n.salesLiveMapPartialUnavailableSalesBranches(
          result.salesUnavailableBranchCount,
        ),
    ];
  }

  static String _agentsSummary(
    SalesLiveMapPresentationState state,
    AppLocalizations l10n,
  ) {
    final branchOptions =
        state.result?.branchOptions ?? const <SalesLiveMapBranchOption>[];
    if (branchOptions.isEmpty) {
      if (state.result != null && !state.isLoading) {
        return l10n.salesLiveMapAgentsNoneSummary;
      }
      return l10n.salesLiveMapAgentsLoadingSummary;
    }
    final selected = state.filter.selectedBranchIds;
    if (selected == null) {
      return l10n.salesLiveMapAgentsAllWithTokenSummary(branchOptions.length);
    }
    return l10n.salesLiveMapAgentsSelectedSummary(selected.length);
  }

  static String _periodSummary(
    SalesLiveMapFilter filter,
    AppLocalizations l10n,
  ) {
    final range = filter.resolveDateRange();
    final rangeLabel = _formatDateRange(range, l10n);
    return switch (filter.periodMode) {
      SalesLiveMapPeriodMode.today => l10n.salesLiveMapPeriodToday,
      SalesLiveMapPeriodMode.lastSevenDays =>
        l10n.salesLiveMapPeriodLastSevenDays,
      SalesLiveMapPeriodMode.currentMonth =>
        l10n.salesLiveMapPeriodCurrentMonth,
      SalesLiveMapPeriodMode.customRange => rangeLabel,
    };
  }

  static String _formatDateRange(
    DashboardDateRange range,
    AppLocalizations l10n,
  ) {
    return l10n.salesLiveMapDateRangeFormat(
      AppBrFormatters.shortDate(range.startInclusive),
      AppBrFormatters.shortDate(range.endInclusive),
    );
  }

  static String _detailLabel(
    SalesLiveMapMapDetail detailLevel,
    AppLocalizations l10n,
  ) {
    return switch (detailLevel) {
      SalesLiveMapMapDetail.branches => l10n.salesLiveMapDetailBranches,
      SalesLiveMapMapDetail.municipalities =>
        l10n.salesLiveMapDetailMunicipalities,
      SalesLiveMapMapDetail.states => l10n.salesLiveMapDetailStates,
    };
  }

  static String _visualLabel(
    SalesLiveMapMarkerVisual visual,
    AppLocalizations l10n,
  ) {
    return switch (visual) {
      SalesLiveMapMarkerVisual.dot => l10n.salesLiveMapVisualDot,
      SalesLiveMapMarkerVisual.bubble => l10n.salesLiveMapVisualBubble,
      SalesLiveMapMarkerVisual.storeIcon => l10n.salesLiveMapVisualStoreIcon,
    };
  }

  static String _mapSubtitle(
    SalesLiveMapPresentationState state,
    AppLocalizations l10n,
  ) {
    final period = _formatDateRange(state.filter.resolveDateRange(), l10n);
    final result = state.result;
    if (result == null || result.salesDataPending) {
      return l10n.salesLiveMapChartSubtitlePending(period);
    }
    final baseSubtitle = l10n.salesLiveMapChartSubtitleLoaded(
      period,
      result.mappedBranchCount,
      result.totalBranchCount,
    );
    if (state.effectiveDetailLevel == SalesLiveMapMapDetail.municipalities &&
        state.filter.detailLevel == SalesLiveMapMapDetail.branches) {
      return '$baseSubtitle ${l10n.salesLiveMapDetailAutoMunicipalities(kSalesLiveMapAutoMunicipalityDetailPointThreshold)}';
    }
    return baseSubtitle;
  }

  static String _loadErrorMessage(
    SalesLiveMapPresentationState state,
    AppLocalizations l10n,
  ) {
    if (state.sessionExpired) {
      return l10n.salesLiveMapSessionExpiredMessage;
    }
    final result = state.result;
    final loadFailure = result?.loadFailure;
    if (loadFailure != null) {
      return agentQueryFailureUserMessage(loadFailure, l10n);
    }
    return switch (result?.loadFailureReason) {
      SalesLiveMapLoadFailureReason.missingClientTokenSetup =>
        l10n.salesLiveMapMissingClientTokenSetupMessage,
      null =>
        result?.loadFailureMessage ?? l10n.salesLiveMapLoadErrorRetryMessage,
    };
  }
}
