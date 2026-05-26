import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref_codec.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';

const int kSalesLiveMapAutoMunicipalityDetailPointThreshold = 200;

@immutable
class SalesLiveMapPresentationState {
  const SalesLiveMapPresentationState({
    this.filter = const SalesLiveMapFilter(),
    this.availableAgents = const <DashboardAgentOption>[],
    this.result,
    this.visualResult,
    this.mapPayloadDigest = 0,
    this.isLoading = true,
    this.sessionExpired = false,
    this.closeFullscreenRequestId = 0,
  });

  final SalesLiveMapFilter filter;
  final List<DashboardAgentOption> availableAgents;
  final SalesLiveMapLoadResult? result;
  final SalesLiveMapLoadResult? visualResult;
  final int mapPayloadDigest;
  final bool isLoading;
  final bool sessionExpired;
  final int closeFullscreenRequestId;

  Set<String> get filterBranchStorageKeys =>
      filter.selectedBranchIds
          ?.map(SalesLiveMapBranchRefCodec.encode)
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

  bool get canReload =>
      !isLoading && (sessionExpired || availableAgents.isNotEmpty);

  bool get hasVisualResult => visualResult != null;

  bool get isMapRefreshing => isLoading && hasVisualResult;

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

  SalesLiveMapVisualSpec get visualSpec {
    return SalesLiveMapVisualSpec.operational(
      detailLevel: effectiveDetailLevel,
      markerVisual: filter.markerVisual,
    );
  }

  SalesLiveMapPresentationState copyWith({
    SalesLiveMapFilter? filter,
    List<DashboardAgentOption>? availableAgents,
    Object? result = _sentinel,
    Object? visualResult = _sentinel,
    int? mapPayloadDigest,
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
      visualResult: identical(visualResult, _sentinel)
          ? this.visualResult
          : visualResult as SalesLiveMapLoadResult?,
      mapPayloadDigest: mapPayloadDigest ?? this.mapPayloadDigest,
      isLoading: isLoading ?? this.isLoading,
      sessionExpired: sessionExpired ?? this.sessionExpired,
      closeFullscreenRequestId:
          closeFullscreenRequestId ?? this.closeFullscreenRequestId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SalesLiveMapPresentationState &&
        other.filter == filter &&
        listEquals(other.availableAgents, availableAgents) &&
        identical(other.result, result) &&
        identical(other.visualResult, visualResult) &&
        other.mapPayloadDigest == mapPayloadDigest &&
        other.isLoading == isLoading &&
        other.sessionExpired == sessionExpired &&
        other.closeFullscreenRequestId == closeFullscreenRequestId;
  }

  @override
  int get hashCode => Object.hash(
    filter,
    Object.hashAll(availableAgents),
    identityHashCode(result),
    identityHashCode(visualResult),
    mapPayloadDigest,
    isLoading,
    sessionExpired,
    closeFullscreenRequestId,
  );
}

const Object _sentinel = Object();
