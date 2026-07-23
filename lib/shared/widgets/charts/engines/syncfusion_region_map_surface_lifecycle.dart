import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_marker_overlay_coordinator.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_shape_source_cache.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_viewport_coordinator.dart';

enum SyncfusionRegionMapSurfaceRemountReason {
  loadingEnded,
  stableKeyChanged,
}

/// Coordinates map-surface remount decisions across viewport, markers, and
/// shape-source cache without remounting SfMaps on routine marker updates.
class SyncfusionRegionMapSurfaceLifecycle {
  int? cachedMapSurfaceStableKey;
  SyncfusionRegionMapSurfaceRemountReason? pendingRemountReason;

  void noteLoadingEnded() {
    pendingRemountReason = SyncfusionRegionMapSurfaceRemountReason.loadingEnded;
  }

  void handleNextStableKey({
    required int nextMapSurfaceStableKey,
    required bool stableKeyChanged,
    required SyncfusionRegionMapMarkerOverlayCoordinator markerOverlay,
    required SyncfusionRegionMapViewportCoordinator viewport,
    required SyncfusionRegionMapShapeSourceCache shapeSourceCache,
    required bool mounted,
    required AppMapViewport? preferredViewport,
    required bool hasPreferredViewport,
    required int pointCount,
    required int itemCount,
  }) {
    if (stableKeyChanged) {
      pendingRemountReason ??=
          SyncfusionRegionMapSurfaceRemountReason.stableKeyChanged;
      markerOverlay.reset();
    }

    final remountReason = pendingRemountReason;
    if (remountReason == null) {
      cachedMapSurfaceStableKey = nextMapSurfaceStableKey;
      return;
    }

    if (remountReason == SyncfusionRegionMapSurfaceRemountReason.loadingEnded &&
        preferredViewport != null) {
      viewport.prepareViewportForLoadingEndedRemount(
        preferredViewport: preferredViewport,
        mounted: mounted,
      );
    }

      viewport
      ..logRemount(
        reason: remountReason.name,
        stableKeyChanged: stableKeyChanged,
        nextMapSurfaceStableKey: nextMapSurfaceStableKey,
        hasPreferredViewport: hasPreferredViewport,
        pointCount: pointCount,
        itemCount: itemCount,
      )
      ..recreateZoomPanBehavior(seedFromState: true)
      ..applyZoomPanBehaviorViewport(
        reason: 'map_surface_remount_${remountReason.name}',
        mounted: mounted,
        isLoading: false,
        shouldLog: false,
      );
    shapeSourceCache.invalidate();
    cachedMapSurfaceStableKey = nextMapSurfaceStableKey;
    pendingRemountReason = null;
  }
}
