import 'package:colmeia/features/sales/presentation/rules/sales_live_map_presentation_rules.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:flutter/foundation.dart';

/// Slice of [SalesLiveMapPresentationState] used by the live map page to
/// detect when auto-refresh scheduling should be re-evaluated.
///
/// Equal slices instruct the page to keep the current schedule untouched,
/// so widening this view triggers more reschedules.
@immutable
class SalesLiveMapSchedulingSlice {
  const SalesLiveMapSchedulingSlice({
    required this.isLoading,
    required this.canScheduleAutoRefresh,
  });

  factory SalesLiveMapSchedulingSlice.fromState(
    SalesLiveMapPresentationState state,
  ) {
    return SalesLiveMapSchedulingSlice(
      isLoading: state.isLoading,
      canScheduleAutoRefresh:
          SalesLiveMapPresentationRules.canScheduleAutoRefresh(state),
    );
  }

  final bool isLoading;
  final bool canScheduleAutoRefresh;

  @override
  bool operator ==(Object other) {
    return other is SalesLiveMapSchedulingSlice &&
        other.isLoading == isLoading &&
        other.canScheduleAutoRefresh == canScheduleAutoRefresh;
  }

  @override
  int get hashCode => Object.hash(isLoading, canScheduleAutoRefresh);
}
