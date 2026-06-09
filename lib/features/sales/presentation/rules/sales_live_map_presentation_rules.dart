import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/models/sales_live_map_visual_spec.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';

/// Mapped branch count above which the live map auto-downgrades the user's
/// chosen `branches` detail level to `municipalities` to keep the map
/// readable.
const int kSalesLiveMapAutoMunicipalityDetailPointThreshold = 200;

/// Pure presentation rules for the sales live map. Keeps
/// [SalesLiveMapPresentationState] free of view-model imports while
/// centralizing product logic used by widgets, slices, and the view model.
abstract final class SalesLiveMapPresentationRules {
  /// True when at least one available agent has a local client token and the
  /// current selection includes at least one of those agents.
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
        currentResult.loadFailed) {
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
    if (state.filter.detailLevel == SalesLiveMapMapDetail.branches &&
        _mappedBranchCountForDetailPolicy(state) >
            kSalesLiveMapAutoMunicipalityDetailPointThreshold) {
      return SalesLiveMapMapDetail.municipalities;
    }
    return state.filter.detailLevel;
  }

  static int _mappedBranchCountForDetailPolicy(
    SalesLiveMapPresentationState state,
  ) {
    if (state.isMapRefreshing && state.visualResult != null) {
      return state.visualResult!.mappedBranchCount;
    }
    return state.result?.mappedBranchCount ?? 0;
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
}
