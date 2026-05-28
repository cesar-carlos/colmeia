import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/sales/application/sales_live_map_reload_reason.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_scheduling_slice.dart';

/// Holds the auto-refresh bookkeeping for `SalesLiveMapPage` and exposes
/// pure helpers that translate controller state changes into reload intent
/// and queued-tick scheduling decisions.
///
/// The page `State` owns one of these and delegates to it instead of keeping
/// the bookkeeping inline. The State is still responsible for invoking
/// `AutoRefreshStateMixin` methods (e.g. `recordAutoRefreshSuccessfulReload`)
/// because those need the mixin context that lives on the State itself.
class SalesLiveMapSessionCoordinator {
  int pendingReloadForceCount = 0;
  SalesLiveMapReloadReason? pendingReloadReason;
  int lastCloseFullscreenRequestId = 0;
  AutoRefreshReloadResult lastAutoRefreshReloadResult =
      const AutoRefreshReloadResult.cancelled();
  DateTime? lastRecordedSuccessfulRefreshAt;
  bool wasControllerLoading = false;
  DateTime? controllerReloadQueuedTickThreshold;
  bool liveMapFullscreenOpen = false;
  SalesLiveMapSchedulingSlice? lastSchedulingSlice;

  /// Records that the user requested a manual reload. When [force] is true,
  /// [pendingReloadForceCount] is incremented so the next consumer honours
  /// the force flag even if multiple manual reloads were queued.
  void markManualReload({required bool force}) {
    if (force) {
      pendingReloadForceCount += 1;
    }
    pendingReloadReason = SalesLiveMapReloadReason.manual;
  }

  /// Returns the parameters for the next controller reload and clears the
  /// pending bookkeeping atomically.
  ({bool force, SalesLiveMapReloadReason reason}) consumePendingReload() {
    final force = pendingReloadForceCount > 0;
    final reason = pendingReloadReason ?? SalesLiveMapReloadReason.autoRefresh;
    pendingReloadForceCount = 0;
    pendingReloadReason = null;
    return (force: force, reason: reason);
  }

  /// Drops any pending manual reload that was never consumed by
  /// `performAutoRefreshReload` (e.g. because `reloadWithAutoRefresh`
  /// short-circuited while another reload was already active). Prevents a
  /// subsequent auto-refresh tick from inheriting `manual` semantics it did
  /// not earn.
  void clearPendingReloadIfNotConsumed() {
    pendingReloadForceCount = 0;
    pendingReloadReason = null;
  }

  /// Resolves the next "queued tick" threshold from the current auto-refresh
  /// configuration, or null when scheduling is paused.
  DateTime? resolveQueuedTickThreshold({
    required AutoRefreshOption? option,
    required DateTime? nextDueAt,
    required DateTime now,
  }) {
    if (option == null || nextDueAt == null) {
      return null;
    }
    if (now.isBefore(nextDueAt)) {
      return nextDueAt;
    }
    return nextDueAt.add(option.duration);
  }

  /// Whether the latest controller reload crossed the previously queued tick.
  bool didControllerReloadCrossQueuedTickThreshold(DateTime now) {
    final threshold = controllerReloadQueuedTickThreshold;
    if (threshold == null) {
      return false;
    }
    return !now.isBefore(threshold);
  }
}
