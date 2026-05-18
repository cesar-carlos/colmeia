import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/l10n/app_localizations.dart';

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
    final usesMapLabel = state.filter.detailLevel == SalesLiveMapMapDetail.states;
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
      fullscreenFilterSummary:
          '${filterParts.join(' · ')} · ${l10n.chartFullscreenDataSnapshotHint}',
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
    final rangeLabel =
        '${AppBrFormatters.shortDate(range.startInclusive)} a ${AppBrFormatters.shortDate(range.endInclusive)}';
    return switch (filter.periodMode) {
      SalesLiveMapPeriodMode.today => l10n.salesLiveMapPeriodToday,
      SalesLiveMapPeriodMode.lastSevenDays =>
        l10n.salesLiveMapPeriodLastSevenDays,
      SalesLiveMapPeriodMode.currentMonth =>
        l10n.salesLiveMapPeriodCurrentMonth,
      SalesLiveMapPeriodMode.customRange => rangeLabel,
    };
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
    final range = state.filter.resolveDateRange();
    final period =
        '${AppBrFormatters.shortDate(range.startInclusive)} a ${AppBrFormatters.shortDate(range.endInclusive)}';
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
    return switch (result?.loadFailureReason) {
      SalesLiveMapLoadFailureReason.missingClientTokenSetup =>
        l10n.salesLiveMapMissingClientTokenSetupMessage,
      null => result?.loadFailureMessage ?? l10n.salesLiveMapLoadErrorRetryMessage,
    };
  }
}
