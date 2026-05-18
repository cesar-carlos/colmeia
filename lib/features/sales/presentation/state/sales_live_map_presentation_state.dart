import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/foundation.dart';

const int kSalesLiveMapAutoMunicipalityDetailPointThreshold = 200;

@immutable
class SalesLiveMapPresentationState {
  const SalesLiveMapPresentationState({
    this.filter = const SalesLiveMapFilter(),
    this.availableAgents = const <OverviewAgentOption>[],
    this.result,
    this.isLoading = true,
    this.sessionExpired = false,
    this.closeFullscreenRequestId = 0,
  });

  final SalesLiveMapFilter filter;
  final List<OverviewAgentOption> availableAgents;
  final SalesLiveMapLoadResult? result;
  final bool isLoading;
  final bool sessionExpired;
  final int closeFullscreenRequestId;

  Set<String> get filterBranchStorageKeys =>
      filter.selectedBranchIds
          ?.map((branch) => branch.toStorageKey())
          .toSet() ??
      const <String>{};

  bool get hasSelectedBranchFilter =>
      filter.selectedBranchIds?.isNotEmpty ?? false;

  bool get hasNonBranchNonDefaultFilter {
    const defaults = SalesLiveMapFilter();
    return filter.selectedAgentIds != defaults.selectedAgentIds ||
        filter.periodMode != defaults.periodMode ||
        filter.customDateRange != defaults.customDateRange ||
        filter.detailLevel != defaults.detailLevel ||
        filter.markerVisual != defaults.markerVisual ||
        filter.metric != defaults.metric;
  }

  bool get canScheduleAutoRefresh {
    final tokenBacked = availableAgents
        .where((agent) => !agent.missingLocalClientToken)
        .map((agent) => agent.agentId)
        .toSet();
    if (tokenBacked.isEmpty) {
      return false;
    }
    final selected = filter.selectedAgentIds;
    if (selected == null) {
      return true;
    }
    return selected.any(tokenBacked.contains);
  }

  bool get canReload => !isLoading && (sessionExpired || availableAgents.isNotEmpty);

  bool get shouldShowEmptyNotice {
    final currentResult = result;
    if (currentResult == null ||
        currentResult.salesDataPending ||
        currentResult.loadFailed ||
        currentResult.hasPartialIssue) {
      return false;
    }
    return currentResult.totalSalesCount == 0 ||
        currentResult.totalBranchCount == 0;
  }

  SalesLiveMapMapDetail get effectiveDetailLevel {
    final currentResult = result;
    if (filter.detailLevel == SalesLiveMapMapDetail.branches &&
        (currentResult?.mappedBranchCount ?? 0) >
            kSalesLiveMapAutoMunicipalityDetailPointThreshold) {
      return SalesLiveMapMapDetail.municipalities;
    }
    return filter.detailLevel;
  }

  AppBrazilStoreSalesMapStyle get mapStyle {
    final detailLevel = effectiveDetailLevel;
    final resolvedVisual = detailLevel == SalesLiveMapMapDetail.states
        ? SalesLiveMapMarkerVisual.bubble
        : filter.markerVisual;
    final appMarkerVisual = switch (resolvedVisual) {
      SalesLiveMapMarkerVisual.dot => AppBrazilStoreSalesMarkerVisual.dot,
      SalesLiveMapMarkerVisual.bubble => AppBrazilStoreSalesMarkerVisual.bubble,
      SalesLiveMapMarkerVisual.storeIcon =>
        AppBrazilStoreSalesMarkerVisual.storeIcon,
    };
    final aggregation = switch (detailLevel) {
      SalesLiveMapMapDetail.branches =>
        AppBrazilStoreSalesMarkerAggregation.stores,
      SalesLiveMapMapDetail.municipalities =>
        AppBrazilStoreSalesMarkerAggregation.municipalities,
      SalesLiveMapMapDetail.states =>
        AppBrazilStoreSalesMarkerAggregation.states,
    };
    final (minSize, maxSize) = switch (resolvedVisual) {
      SalesLiveMapMarkerVisual.dot => (10.0, 24.0),
      SalesLiveMapMarkerVisual.bubble =>
        detailLevel == SalesLiveMapMapDetail.states
            ? (30.0, 76.0)
            : (34.0, 82.0),
      SalesLiveMapMarkerVisual.storeIcon => (24.0, 34.0),
    };

    return AppBrazilStoreSalesMapStyle(
      height: 560,
      markerVisual: appMarkerVisual,
      markerAggregation: aggregation,
      markerMinSize: minSize,
      markerMaxSize: maxSize,
      maxClusterTooltipStores:
          detailLevel == SalesLiveMapMapDetail.municipalities ? 8 : 5,
      showStoreDetail: detailLevel != SalesLiveMapMapDetail.states,
      showRegionFilter: false,
      enableProximityCluster: detailLevel == SalesLiveMapMapDetail.branches,
    );
  }

  SalesLiveMapPresentationState copyWith({
    SalesLiveMapFilter? filter,
    List<OverviewAgentOption>? availableAgents,
    Object? result = _sentinel,
    bool? isLoading,
    bool? sessionExpired,
    int? closeFullscreenRequestId,
  }) {
    return SalesLiveMapPresentationState(
      filter: filter ?? this.filter,
      availableAgents: availableAgents ?? this.availableAgents,
      result: identical(result, _sentinel)
          ? this.result
          : result as SalesLiveMapLoadResult?,
      isLoading: isLoading ?? this.isLoading,
      sessionExpired: sessionExpired ?? this.sessionExpired,
      closeFullscreenRequestId:
          closeFullscreenRequestId ?? this.closeFullscreenRequestId,
    );
  }
}

const Object _sentinel = Object();
