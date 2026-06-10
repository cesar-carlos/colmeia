import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_marker_overlay_coordinator.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_shape_source_cache.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_surface_lifecycle.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_viewport_coordinator.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_viewport_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SyncfusionRegionMapSurfaceLifecycle lifecycle;
  late SyncfusionRegionMapMarkerOverlayCoordinator markerOverlay;
  late SyncfusionRegionMapViewportCoordinator viewport;
  late SyncfusionRegionMapShapeSourceCache shapeSourceCache;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    lifecycle = SyncfusionRegionMapSurfaceLifecycle();
    markerOverlay = SyncfusionRegionMapMarkerOverlayCoordinator()
      ..markersOverlayReady = true
      ..markerOverlayMountGeneration = 3;
    viewport = SyncfusionRegionMapViewportCoordinator(operationLabel: 'test')
      ..recreateZoomPanBehavior()
      ..state = const SyncfusionRegionMapViewportState(
        zoomLevel: 2.5,
        centerLatitude: -15,
        centerLongitude: -56,
      );
    shapeSourceCache = SyncfusionRegionMapShapeSourceCache();
  });

  group('SyncfusionRegionMapSurfaceLifecycle', () {
    test('caches stable key when no remount is pending', () {
      lifecycle.handleNextStableKey(
        nextMapSurfaceStableKey: 7,
        stableKeyChanged: false,
        markerOverlay: markerOverlay,
        viewport: viewport,
        shapeSourceCache: shapeSourceCache,
        mounted: true,
        preferredViewport: null,
        hasPreferredViewport: false,
        pointCount: 2,
        itemCount: 1,
      );

      expect(lifecycle.cachedMapSurfaceStableKey, 7);
      expect(lifecycle.pendingRemountReason, isNull);
      expect(markerOverlay.markersOverlayReady, isTrue);
      expect(markerOverlay.markerOverlayMountGeneration, 3);
    });

    test('resets marker overlay when stable key changes without remount', () {
      lifecycle.handleNextStableKey(
        nextMapSurfaceStableKey: 8,
        stableKeyChanged: true,
        markerOverlay: markerOverlay,
        viewport: viewport,
        shapeSourceCache: shapeSourceCache,
        mounted: true,
        preferredViewport: null,
        hasPreferredViewport: false,
        pointCount: 2,
        itemCount: 1,
      );

      expect(markerOverlay.markersOverlayReady, isFalse);
      expect(markerOverlay.markerOverlayMountGeneration, 0);
      expect(lifecycle.pendingRemountReason, isNull);
      expect(lifecycle.cachedMapSurfaceStableKey, 8);
    });

    test('remounts surface after loading ends and clears pending reason', () {
      lifecycle
        ..noteLoadingEnded()
        ..handleNextStableKey(
          nextMapSurfaceStableKey: 9,
          stableKeyChanged: false,
          markerOverlay: markerOverlay,
          viewport: viewport,
          shapeSourceCache: shapeSourceCache,
          mounted: true,
          preferredViewport: const AppMapViewport(
            zoomLevel: 3,
            centerLatitude: -23,
            centerLongitude: -46,
          ),
          hasPreferredViewport: true,
          pointCount: 4,
          itemCount: 2,
        );

      expect(lifecycle.pendingRemountReason, isNull);
      expect(lifecycle.cachedMapSurfaceStableKey, 9);
      expect(viewport.state.zoomLevel, 3);
      expect(viewport.state.centerLatitude, -23);
      expect(viewport.state.centerLongitude, -46);
      expect(viewport.zoomPanBehavior.zoomLevel, 3);
    });

    test('prefers loadingEnded remount reason over stableKeyChanged', () {
      lifecycle
        ..noteLoadingEnded()
        ..handleNextStableKey(
          nextMapSurfaceStableKey: 10,
          stableKeyChanged: true,
          markerOverlay: markerOverlay,
          viewport: viewport,
          shapeSourceCache: shapeSourceCache,
          mounted: true,
          preferredViewport: null,
          hasPreferredViewport: false,
          pointCount: 1,
          itemCount: 1,
        );

      expect(lifecycle.pendingRemountReason, isNull);
      expect(markerOverlay.markersOverlayReady, isFalse);
    });
  });
}
