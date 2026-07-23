import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_viewport_coordinator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

void main() {
  late SyncfusionRegionMapViewportCoordinator coordinator;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    coordinator = SyncfusionRegionMapViewportCoordinator(operationLabel: 'test')
      ..updateConfig(
        minZoomLevel: 1,
        maxZoomLevel: 5,
        isZoomPanEnabled: true,
        enableDoubleTapZooming: true,
        showToolbar: false,
      )
      ..recreateZoomPanBehavior();
  });

  group('SyncfusionRegionMapViewportCoordinator', () {
    test('clampZoomLevel respects configured min and max', () {
      expect(coordinator.clampZoomLevel(0.5), 1);
      expect(coordinator.clampZoomLevel(3), 3);
      expect(coordinator.clampZoomLevel(8), 5);
    });

    test('shouldIgnoreGestureViewportFeedback when suppression is active', () {
      coordinator.state = coordinator.state.copyWith(
        suppressProgrammaticViewportEvents: true,
      );

      expect(coordinator.shouldIgnoreGestureViewportFeedback(), isTrue);
    });

    test('handleWillZoom ignores feedback while suppression is active', () {
      coordinator.state = coordinator.state.copyWith(
        suppressProgrammaticViewportEvents: true,
        zoomLevel: 2,
      );
      var callbackCount = 0;

      coordinator.handleWillZoom(
        newZoomLevel: 3,
        newVisibleBounds: null,
        onViewportChanged: (_) => callbackCount++,
      );

      expect(coordinator.state.zoomLevel, 2);
      expect(callbackCount, 0);
    });

    test('handleWillZoom emits user viewport change when not suppressed', () {
      AppMapViewportChangedEvent? captured;
      coordinator
        ..state = coordinator.state.copyWith(zoomLevel: 2)
        ..handleWillZoom(
          newZoomLevel: 3.2,
          newVisibleBounds: null,
          onViewportChanged: (event) => captured = event,
        );

      expect(coordinator.state.zoomLevel, 3.2);
      expect(captured?.source, AppMapViewportChangeSource.user);
      expect(captured?.viewport.zoomLevel, 3.2);
    });

    test('applyZoomPanBehaviorViewport returns false when not mounted', () {
      final applied = coordinator.applyZoomPanBehaviorViewport(
        reason: 'test',
        mounted: false,
        isLoading: false,
      );

      expect(applied, isFalse);
    });

    test('applyZoomPanBehaviorViewport syncs behavior when state drifts', () {
      coordinator.state = coordinator.state.copyWith(
        zoomLevel: 2.5,
        centerLatitude: -15.0,
        centerLongitude: -56.0,
      );

      final applied = coordinator.applyZoomPanBehaviorViewport(
        reason: 'test',
        mounted: true,
        isLoading: false,
        shouldLog: false,
      );

      expect(applied, isTrue);
      expect(coordinator.zoomPanBehavior.zoomLevel, 2.5);
      expect(coordinator.zoomPanBehavior.focalLatLng?.latitude, -15);
      expect(coordinator.zoomPanBehavior.focalLatLng?.longitude, -56);
    });

    test(
      'markMapSurfaceDetached recreates behavior so disposed Syncfusion '
      'controllers are not reused',
      () {
        final previous = coordinator.zoomPanBehavior;
        coordinator
          ..markMapSurfaceAttached()
          ..state = coordinator.state.copyWith(zoomLevel: 3.2)
          ..markMapSurfaceDetached();

        expect(coordinator.mapSurfaceAttached, isFalse);
        expect(identical(coordinator.zoomPanBehavior, previous), isFalse);
        expect(coordinator.zoomPanBehavior.zoomLevel, 3.2);
      },
    );

    test(
      'applyZoomPanBehaviorViewport seeds a fresh behavior while detached',
      () {
        final previous = coordinator.zoomPanBehavior;
        coordinator
          ..mapSurfaceAttached = false
          ..state = coordinator.state.copyWith(
            zoomLevel: 2.75,
            centerLatitude: -22.0,
            centerLongitude: -43.0,
          );

        final applied = coordinator.applyZoomPanBehaviorViewport(
          reason: 'detached_seed',
          mounted: true,
          isLoading: false,
          shouldLog: false,
        );

        expect(applied, isTrue);
        expect(identical(coordinator.zoomPanBehavior, previous), isFalse);
        expect(coordinator.zoomPanBehavior.zoomLevel, 2.75);
        expect(coordinator.zoomPanBehavior.focalLatLng?.latitude, -22);
        expect(coordinator.zoomPanBehavior.focalLatLng?.longitude, -43);
      },
    );

    test('applyPreferredViewport skips when user has manual viewport', () {
      coordinator
        ..state = coordinator.state.copyWith(userHasManualViewport: true)
        ..applyPreferredViewport(
          mounted: true,
          isLoading: false,
          isPreferredViewportSuppressed: false,
          preferredViewport: const AppMapViewport(
            zoomLevel: 3,
            centerLatitude: -23,
            centerLongitude: -46,
          ),
          pointCount: 1,
          itemCount: 1,
        );

      expect(coordinator.zoomPanBehavior.zoomLevel, 1);
      expect(coordinator.lastAppliedPreferredViewport, isNull);
    });

    test(
      'applyPreferredViewport applies override even with manual viewport',
      () {
        coordinator
          ..state = coordinator.state.copyWith(userHasManualViewport: true)
          ..applyPreferredViewport(
            mounted: true,
            isLoading: false,
            isPreferredViewportSuppressed: false,
            preferredViewport: const AppMapViewport(
              zoomLevel: 3,
              centerLatitude: -23,
              centerLongitude: -46,
            ),
            pointCount: 1,
            itemCount: 1,
            overrideManualViewport: true,
            viewportOverride: const AppMapViewport(
              zoomLevel: 4,
              centerLatitude: -10,
              centerLongitude: -50,
            ),
          );

        expect(coordinator.state.zoomLevel, 4);
        expect(coordinator.zoomPanBehavior.zoomLevel, 4);
        expect(coordinator.lastAppliedPreferredViewport?.centerLatitude, -10);
      },
    );

    test('handlePointerScrollZoom increases zoom on scroll up', () {
      coordinator.state = coordinator.state.copyWith(zoomLevel: 2);
      var manualStateScheduled = false;
      AppMapViewportChangedEvent? captured;

      coordinator.handlePointerScrollZoom(
        event: const PointerScrollEvent(
          scrollDelta: Offset(0, -120),
        ),
        mounted: () => true,
        isLoading: false,
        onViewportChanged: (event) => captured = event,
        scheduleManualViewportState: () => manualStateScheduled = true,
      );

      expect(
        coordinator.state.zoomLevel,
        greaterThan(2),
      );
      expect(captured?.source, AppMapViewportChangeSource.user);
      expect(manualStateScheduled, isTrue);
    });

    test('resetPreferredViewport clears manual state and applies target', () {
      coordinator
        ..state = coordinator.state.copyWith(userHasManualViewport: true)
        ..lastAppliedPreferredViewport = const AppMapViewport(zoomLevel: 2)
        ..lockPreferredViewportReapply = true;
      var scheduleCount = 0;

      coordinator.resetPreferredViewport(
        resetViewport: const AppMapViewport(
          zoomLevel: 2.8,
          centerLatitude: -12,
          centerLongitude: -55,
        ),
        preferredViewport: null,
        onResetViewport: null,
        mounted: true,
        isLoading: false,
        isPreferredViewportSuppressed: false,
        pointCount: 1,
        itemCount: 1,
        scheduleState: () => scheduleCount++,
      );

      expect(coordinator.state.userHasManualViewport, isFalse);
      expect(coordinator.lastAppliedPreferredViewport?.zoomLevel, 2.8);
      expect(coordinator.lockPreferredViewportReapply, isTrue);
      expect(scheduleCount, 1);
    });

    test('prepareViewportForLoadingEndedRemount seeds viewport state', () {
      coordinator.prepareViewportForLoadingEndedRemount(
        preferredViewport: const AppMapViewport(
          zoomLevel: 3.5,
          centerLatitude: -20,
          centerLongitude: -45,
        ),
        mounted: true,
      );

      expect(coordinator.state.zoomLevel, 3.5);
      expect(coordinator.state.centerLatitude, -20.0);
      expect(coordinator.state.centerLongitude, -45.0);
      expect(coordinator.state.userHasManualViewport, isFalse);
      expect(coordinator.state.suppressProgrammaticViewportEvents, isTrue);
    });

    test('scheduleManualViewportState defers manual flag until next frame', () {
      coordinator.scheduleManualViewportState(
        mounted: () => true,
        scheduleState: () {},
      );

      expect(coordinator.state.userHasManualViewport, isFalse);
    });

    test('initFromZoomPanBehavior copies behavior focal point into state', () {
      final behavior = MapZoomPanBehavior(
        zoomLevel: 2.2,
        focalLatLng: const MapLatLng(-14, -57),
      );

      coordinator.initFromZoomPanBehavior(behavior);

      expect(coordinator.state.zoomLevel, 2.2);
      expect(coordinator.state.centerLatitude, -14);
      expect(coordinator.state.centerLongitude, -57);
    });
  });
}
