import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_viewport_state.dart';
import 'package:colmeia/shared/widgets/charts/region_map_viewport_sync_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

/// Viewport state machine and Syncfusion [MapZoomPanBehavior] sync for the
/// region map engine.
class SyncfusionRegionMapViewportCoordinator {
  SyncfusionRegionMapViewportCoordinator({
    required this.operationLabel,
  });

  static const double mouseWheelZoomStep = 0.35;

  final String operationLabel;

  double minZoomLevel = 1;
  double maxZoomLevel = 5;
  bool isZoomPanEnabled = false;
  bool enableDoubleTapZooming = false;
  bool showToolbar = false;

  void updateConfig({
    required double minZoomLevel,
    required double maxZoomLevel,
    required bool isZoomPanEnabled,
    required bool enableDoubleTapZooming,
    required bool showToolbar,
  }) {
    this.minZoomLevel = minZoomLevel;
    this.maxZoomLevel = maxZoomLevel;
    this.isZoomPanEnabled = isZoomPanEnabled;
    this.enableDoubleTapZooming = enableDoubleTapZooming;
    this.showToolbar = showToolbar;
  }

  late MapZoomPanBehavior zoomPanBehavior;
  SyncfusionRegionMapViewportState state =
      const SyncfusionRegionMapViewportState(
        zoomLevel: 1,
      );
  AppMapViewport? lastAppliedPreferredViewport;
  bool lockPreferredViewportReapply = false;

  void initFromZoomPanBehavior(MapZoomPanBehavior behavior) {
    zoomPanBehavior = behavior;
    state = SyncfusionRegionMapViewportState(
      zoomLevel: clampZoomLevel(behavior.zoomLevel),
      centerLatitude: behavior.focalLatLng?.latitude,
      centerLongitude: behavior.focalLatLng?.longitude,
    );
  }

  MapZoomPanBehavior buildZoomPanBehavior() {
    return MapZoomPanBehavior(
      enablePanning: isZoomPanEnabled,
      enablePinching: isZoomPanEnabled,
      enableDoubleTapZooming: isZoomPanEnabled && enableDoubleTapZooming,
      minZoomLevel: minZoomLevel,
      maxZoomLevel: maxZoomLevel,
      showToolbar: showToolbar,
    );
  }

  void recreateZoomPanBehavior() {
    zoomPanBehavior = buildZoomPanBehavior();
  }

  void updateZoomPanBehaviorFlags({
    required bool enableDoubleTapZooming,
    required bool showToolbar,
  }) {
    zoomPanBehavior
      ..enablePanning = isZoomPanEnabled
      ..enablePinching = isZoomPanEnabled
      ..enableDoubleTapZooming = isZoomPanEnabled && enableDoubleTapZooming
      ..minZoomLevel = minZoomLevel
      ..maxZoomLevel = maxZoomLevel
      ..showToolbar = showToolbar;
    state = clampedViewportState(state);
  }

  double clampZoomLevel(double zoomLevel) {
    return zoomLevel.clamp(minZoomLevel, maxZoomLevel);
  }

  SyncfusionRegionMapViewportState clampedViewportState(
    SyncfusionRegionMapViewportState viewportState,
  ) {
    return viewportState.copyWith(
      zoomLevel: clampZoomLevel(viewportState.zoomLevel),
    );
  }

  bool shouldIgnoreGestureViewportFeedback() {
    return state.suppressProgrammaticViewportEvents;
  }

  void handleWillZoom({
    required double? newZoomLevel,
    required MapLatLngBounds? newVisibleBounds,
    required ValueChanged<AppMapViewportChangedEvent>? onViewportChanged,
    void Function()? scheduleManualViewportState,
  }) {
    if (shouldIgnoreGestureViewportFeedback()) {
      return;
    }
    state = state.copyWith(
      zoomLevel: clampZoomLevel(newZoomLevel ?? state.zoomLevel),
    );
    emitViewportChanged(
      source: RegionMapViewportSyncPolicy.changeSourceForUserPinchOrPan(),
      onViewportChanged: onViewportChanged,
      bounds: newVisibleBounds,
      scheduleManualViewportState: scheduleManualViewportState,
    );
  }

  void handleWillPan({
    required double? zoomLevel,
    required MapLatLngBounds? newVisibleBounds,
    required ValueChanged<AppMapViewportChangedEvent>? onViewportChanged,
    void Function()? scheduleManualViewportState,
  }) {
    if (shouldIgnoreGestureViewportFeedback()) {
      return;
    }
    state = state.copyWith(
      zoomLevel: clampZoomLevel(zoomLevel ?? state.zoomLevel),
    );
    emitViewportChanged(
      source: RegionMapViewportSyncPolicy.changeSourceForUserPinchOrPan(),
      onViewportChanged: onViewportChanged,
      bounds: newVisibleBounds,
      scheduleManualViewportState: scheduleManualViewportState,
    );
  }

  void handlePointerScrollZoom({
    required PointerScrollEvent event,
    required bool Function() mounted,
    required bool isLoading,
    required ValueChanged<AppMapViewportChangedEvent>? onViewportChanged,
    required void Function() scheduleManualViewportState,
  }) {
    if (!mounted() ||
        event.scrollDelta.dy == 0 ||
        !RegionMapViewportSyncPolicy.allowsPointerWheelZoom(
          isZoomPanEnabled: isZoomPanEnabled,
        )) {
      return;
    }

    final currentZoom = state.zoomLevel;
    final direction = event.scrollDelta.dy < 0 ? 1.0 : -1.0;
    final nextZoom = clampZoomLevel(
      currentZoom + direction * mouseWheelZoomStep,
    );

    if ((nextZoom - currentZoom).abs() < 0.001) {
      return;
    }

    state = state.copyWith(zoomLevel: nextZoom);
    final applied = applyZoomPanBehaviorViewport(
      reason: 'pointer_wheel_zoom',
      mounted: mounted(),
      isLoading: isLoading,
    );
    if (!applied) {
      return;
    }
    scheduleManualViewportState();
    emitViewportChanged(
      source: AppMapViewportChangeSource.user,
      onViewportChanged: onViewportChanged,
    );
  }

  void resetPreferredViewport({
    required AppMapViewport? resetViewport,
    required AppMapViewport? preferredViewport,
    required VoidCallback? onResetViewport,
    required bool mounted,
    required bool isLoading,
    required bool isPreferredViewportSuppressed,
    required int pointCount,
    required int itemCount,
    required void Function() scheduleState,
  }) {
    onResetViewport?.call();
    state = state.copyWith(userHasManualViewport: false);
    lastAppliedPreferredViewport = null;
    lockPreferredViewportReapply = false;
    scheduleState();
    final target = resetViewport ?? preferredViewport;
    if (target == null) {
      return;
    }
    applyPreferredViewport(
      mounted: mounted,
      isLoading: isLoading,
      isPreferredViewportSuppressed: isPreferredViewportSuppressed,
      preferredViewport: preferredViewport,
      pointCount: pointCount,
      itemCount: itemCount,
      overrideManualViewport: true,
      viewportOverride: target,
    );
  }

  void applyPreferredViewport({
    required bool mounted,
    required bool isLoading,
    required bool isPreferredViewportSuppressed,
    required AppMapViewport? preferredViewport,
    required int pointCount,
    required int itemCount,
    bool overrideManualViewport = false,
    AppMapViewport? viewportOverride,
  }) {
    if (!mounted || isLoading) {
      _logViewportGuard(
        'preferred_viewport_skipped',
        mounted: mounted,
        isLoading: isLoading,
      );
      return;
    }

    if (isPreferredViewportSuppressed && viewportOverride == null) {
      _logViewportGuard('preferred_viewport_skipped_store_selection');
      return;
    }

    final viewport = viewportOverride ?? preferredViewport;
    if (viewport == null) {
      state = state.copyWith(userHasManualViewport: false);
      return;
    }

    if (!overrideManualViewport && state.userHasManualViewport) {
      _logViewportGuard('preferred_viewport_skipped_manual');
      return;
    }

    if (_preferredViewportMatches(lastAppliedPreferredViewport, viewport)) {
      _logViewportGuard('preferred_viewport_skipped_unchanged');
      return;
    }

    state = clampedViewportState(
      state.copyWith(
        zoomLevel: viewport.zoomLevel,
        centerLatitude: viewport.centerLatitude,
        centerLongitude: viewport.centerLongitude,
        userHasManualViewport:
            !overrideManualViewport && state.userHasManualViewport,
        suppressProgrammaticViewportEvents: true,
      ),
    );
    _logViewportLifecycle(
      'Applying preferred viewport',
      context: <String, Object?>{
        'operation': operationLabel,
        'zoomLevel': state.zoomLevel,
        'centerLatitude': state.centerLatitude,
        'centerLongitude': state.centerLongitude,
        'pointCount': pointCount,
        'itemCount': itemCount,
      },
    );
    applyZoomPanBehaviorViewport(
      reason: 'preferred_viewport',
      mounted: mounted,
      isLoading: isLoading,
    );
    lastAppliedPreferredViewport = viewport;
    lockPreferredViewportReapply = true;
    _releaseProgrammaticViewportSuppressionAfterFrame(mounted: mounted);
  }

  void prepareViewportForLoadingEndedRemount({
    required AppMapViewport preferredViewport,
    required bool mounted,
  }) {
    state = clampedViewportState(
      state.copyWith(
        zoomLevel: preferredViewport.zoomLevel,
        centerLatitude: preferredViewport.centerLatitude,
        centerLongitude: preferredViewport.centerLongitude,
        userHasManualViewport: false,
        suppressProgrammaticViewportEvents: true,
      ),
    );
    _releaseProgrammaticViewportSuppressionAfterFrame(mounted: mounted);
  }

  bool applyZoomPanBehaviorViewport({
    required String reason,
    required bool mounted,
    required bool isLoading,
    bool shouldLog = true,
    bool suppressViewportCallbacks = false,
  }) {
    if (!mounted || isLoading) {
      _logViewportGuard(
        reason,
        mounted: mounted,
        isLoading: isLoading,
      );
      return false;
    }

    if (!RegionMapViewportSyncPolicy.zoomPanBehaviorDriftsFromViewportState(
      behaviorZoomLevel: zoomPanBehavior.zoomLevel,
      behaviorCenterLatitude: zoomPanBehavior.focalLatLng?.latitude,
      behaviorCenterLongitude: zoomPanBehavior.focalLatLng?.longitude,
      stateZoomLevel: state.zoomLevel,
      stateCenterLatitude: state.centerLatitude,
      stateCenterLongitude: state.centerLongitude,
    )) {
      return false;
    }

    final previousSuppression = state.suppressProgrammaticViewportEvents;
    if (suppressViewportCallbacks) {
      state = state.copyWith(suppressProgrammaticViewportEvents: true);
    }

    state = clampedViewportState(state);
    zoomPanBehavior.zoomLevel = state.zoomLevel;
    if (state.centerLatitude != null && state.centerLongitude != null) {
      zoomPanBehavior.focalLatLng = MapLatLng(
        state.centerLatitude!,
        state.centerLongitude!,
      );
    }
    if (shouldLog) {
      _logViewportLifecycle(
        'Applied zoom pan behavior viewport',
        context: <String, Object?>{
          'operation': operationLabel,
          'reason': reason,
          'zoomLevel': state.zoomLevel,
          'centerLatitude': state.centerLatitude,
          'centerLongitude': state.centerLongitude,
        },
      );
    }

    if (suppressViewportCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        state = state.copyWith(
          suppressProgrammaticViewportEvents: previousSuppression,
        );
      });
    }
    return true;
  }

  void emitViewportChanged({
    required AppMapViewportChangeSource source,
    required ValueChanged<AppMapViewportChangedEvent>? onViewportChanged,
    MapLatLngBounds? bounds,
    void Function()? scheduleManualViewportState,
  }) {
    if (state.suppressProgrammaticViewportEvents) {
      return;
    }

    final centerLatitude = bounds == null
        ? state.centerLatitude
        : (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final centerLongitude = bounds == null
        ? state.centerLongitude
        : (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

    state = clampedViewportState(
      state.copyWith(
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
      ),
    );
    if (source == AppMapViewportChangeSource.user) {
      scheduleManualViewportState?.call();
    }

    final callback = onViewportChanged;
    if (callback == null) {
      return;
    }

    callback(
      AppMapViewportChangedEvent(
        viewport: AppMapViewport(
          zoomLevel: state.zoomLevel,
          centerLatitude: state.centerLatitude,
          centerLongitude: state.centerLongitude,
          bounds: bounds == null
              ? null
              : AppMapViewportBounds(
                  north: bounds.northeast.latitude,
                  south: bounds.southwest.latitude,
                  east: bounds.northeast.longitude,
                  west: bounds.southwest.longitude,
                ),
        ),
        source: source,
      ),
    );
  }

  void scheduleManualViewportState({
    required bool Function() mounted,
    required void Function() scheduleState,
  }) {
    if (state.userHasManualViewport) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted()) {
        return;
      }
      state = state.copyWith(userHasManualViewport: true);
      scheduleState();
    });
  }

  void logRemount({
    required String reason,
    required bool stableKeyChanged,
    required int nextMapSurfaceStableKey,
    required bool hasPreferredViewport,
    required int pointCount,
    required int itemCount,
  }) {
    _logViewportLifecycle(
      'Recreating zoom pan behavior',
      context: <String, Object?>{
        'operation': operationLabel,
        'reason': reason,
        'stableKeyChanged': stableKeyChanged,
        'nextMapSurfaceStableKey': nextMapSurfaceStableKey,
        'zoomLevel': state.zoomLevel,
        'hasPreferredViewport': hasPreferredViewport,
        'userHasManualViewport': state.userHasManualViewport,
        'pointCount': pointCount,
        'itemCount': itemCount,
      },
    );
  }

  bool _preferredViewportMatches(
    AppMapViewport? previous,
    AppMapViewport next,
  ) {
    if (previous == null) {
      return false;
    }
    if ((previous.zoomLevel - next.zoomLevel).abs() >=
        BrazilMapLayoutConstants.preferredViewportZoomEpsilon) {
      return false;
    }
    final previousLat = previous.centerLatitude;
    final previousLng = previous.centerLongitude;
    final nextLat = next.centerLatitude;
    final nextLng = next.centerLongitude;
    if (previousLat == null ||
        previousLng == null ||
        nextLat == null ||
        nextLng == null) {
      return previousLat == nextLat && previousLng == nextLng;
    }
    return (previousLat - nextLat).abs() <
            BrazilMapLayoutConstants.preferredViewportCenterEpsilon &&
        (previousLng - nextLng).abs() <
            BrazilMapLayoutConstants.preferredViewportCenterEpsilon;
  }

  void _releaseProgrammaticViewportSuppressionAfterFrame({
    required bool mounted,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(suppressProgrammaticViewportEvents: false);
    });
  }

  void _logViewportGuard(
    String reason, {
    bool mounted = true,
    bool isLoading = false,
  }) {
    _logViewportLifecycle(
      'Skipping viewport behavior update',
      context: <String, Object?>{
        'operation': operationLabel,
        'reason': reason,
        'mounted': mounted,
        'isLoading': isLoading,
      },
    );
  }

  void _logViewportLifecycle(
    String message, {
    required Map<String, Object?> context,
  }) {
    if (!kDebugMode && !kProfileMode) {
      return;
    }
    AppLogger.debug(message, context: context);
  }
}
