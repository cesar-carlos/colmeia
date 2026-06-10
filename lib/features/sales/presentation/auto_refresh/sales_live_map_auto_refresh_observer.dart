import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:colmeia/features/sales/presentation/coordinators/sales_live_map_session_coordinator.dart';
import 'package:colmeia/features/sales/presentation/rules/sales_live_map_presentation_rules.dart';
import 'package:colmeia/features/sales/presentation/state/sales_live_map_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/view_models/sales_live_map_view_model.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_scheduling_slice.dart';

/// Reacts to controller state changes and updates the auto-refresh
/// bookkeeping via the page coordinator + mixin callbacks.
///
/// Lives separate from the page `State` so the orchestration logic
/// (queued-tick threshold detection, fullscreen pop request handling,
/// scheduling slice reconciliation) can be reasoned about and tested
/// without pulling in the widget tree.
class SalesLiveMapAutoRefreshObserver {
  SalesLiveMapAutoRefreshObserver({
    required this.coordinator,
    required this.readAutoRefreshOption,
    required this.readAutoRefreshNextDueAt,
    required this.readCurrentAutoRefreshTime,
    required this.readAutoRefreshReloadInProgress,
    required this.refreshAutoRefreshScheduling,
    required this.recordAutoRefreshSuccessfulReload,
    required this.onCloseFullscreenRequested,
  });

  final SalesLiveMapSessionCoordinator coordinator;
  final AutoRefreshOption? Function() readAutoRefreshOption;
  final DateTime? Function() readAutoRefreshNextDueAt;
  final DateTime Function() readCurrentAutoRefreshTime;
  final bool Function() readAutoRefreshReloadInProgress;
  final void Function() refreshAutoRefreshScheduling;
  final void Function(DateTime refreshedAt, {required bool scheduleNextCycle})
  recordAutoRefreshSuccessfulReload;
  final void Function() onCloseFullscreenRequested;

  /// Called from the page whenever the controller emits a new state.
  void onControllerChanged(SalesLiveMapPresentationState state) {
    final wasControllerLoading = coordinator.wasControllerLoading;
    final reloadInProgress = readAutoRefreshReloadInProgress();
    if (state.isLoading && !wasControllerLoading && !reloadInProgress) {
      coordinator.controllerReloadQueuedTickThreshold = coordinator
          .resolveQueuedTickThreshold(
            option: readAutoRefreshOption(),
            nextDueAt: readAutoRefreshNextDueAt(),
            now: readCurrentAutoRefreshTime(),
          );
    }
    if (state.isLoading) {
      coordinator.lastRecordedSuccessfulRefreshAt = null;
    }
    if (!state.isLoading &&
        !SalesLiveMapPresentationRules.canScheduleAutoRefresh(state)) {
      coordinator.controllerReloadQueuedTickThreshold = null;
    }
    final schedulingSlice = SalesLiveMapSchedulingSlice.fromState(state);
    if (coordinator.lastSchedulingSlice != schedulingSlice) {
      coordinator.lastSchedulingSlice = schedulingSlice;
      refreshAutoRefreshScheduling();
    }
    final successfulRefreshAt =
        SalesLiveMapViewModel.resolveSuccessfulRefreshAt(
          state,
        );
    if (successfulRefreshAt != null &&
        !reloadInProgress &&
        successfulRefreshAt != coordinator.lastRecordedSuccessfulRefreshAt) {
      final shouldQueueElapsedTick = coordinator
          .didControllerReloadCrossQueuedTickThreshold(
            readCurrentAutoRefreshTime(),
          );
      coordinator.lastRecordedSuccessfulRefreshAt = successfulRefreshAt;
      coordinator.controllerReloadQueuedTickThreshold = null;
      recordAutoRefreshSuccessfulReload(
        successfulRefreshAt,
        scheduleNextCycle: !shouldQueueElapsedTick,
      );
    } else if (!state.isLoading && wasControllerLoading) {
      coordinator.controllerReloadQueuedTickThreshold = null;
    }
    coordinator.wasControllerLoading = state.isLoading;
    if (state.closeFullscreenRequestId !=
        coordinator.lastCloseFullscreenRequestId) {
      coordinator.lastCloseFullscreenRequestId = state.closeFullscreenRequestId;
      onCloseFullscreenRequested();
    }
  }
}
