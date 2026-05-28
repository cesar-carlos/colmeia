import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref_codec.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';

/// Identity-keyed cache for `SalesLiveMapPresentationState.tokenBackedAgentIds`.
/// `Expando` preserves the `const` constructor and weak-references state
/// instances so cached sets are reclaimed with their owners.
final Expando<Set<String>> _tokenBackedAgentIdsExpando =
    Expando<Set<String>>('SalesLiveMapPresentationState.tokenBackedAgentIds');

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

  bool get canScheduleAutoRefresh =>
      SalesLiveMapViewModel.canScheduleAutoRefresh(this);

  /// Memoized projection of `availableAgents` to the subset of agent ids
  /// that carry a local client token. Recomputed on demand per state
  /// instance and cached via an external `Expando`, so neighbouring slices
  /// can read it multiple times per notification without rebuilding the
  /// set each time.
  Set<String> get tokenBackedAgentIds {
    final cached = _tokenBackedAgentIdsExpando[this];
    if (cached != null) {
      return cached;
    }
    final computed = availableAgents.tokenBackedAgentIds();
    _tokenBackedAgentIdsExpando[this] = computed;
    return computed;
  }

  bool get canReload =>
      !isLoading && (sessionExpired || availableAgents.isNotEmpty);

  bool get hasVisualResult => visualResult != null;

  bool get isMapRefreshing => isLoading && hasVisualResult;

  bool get shouldShowEmptyNotice =>
      SalesLiveMapViewModel.shouldShowEmptyNotice(this);

  SalesLiveMapMapDetail get effectiveDetailLevel =>
      SalesLiveMapViewModel.effectiveDetailLevel(this);

  SalesLiveMapVisualSpec get visualSpec => SalesLiveMapViewModel.visualSpec(this);

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
