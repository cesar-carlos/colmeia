import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_viewport_coordinator.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_zoom_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrazilMapPreferredViewportPolicy', () {
    const selectedPoint = AppBrazilStoreSalesPoint(
      id: 'store-1',
      name: 'Store',
      uf: 'MT',
      latitude: -15.6,
      longitude: -56.1,
      salesAmount: 10,
      salesCount: 1,
    );

    test('returns null when user has manual viewport', () {
      final result = BrazilMapPreferredViewportPolicy.resolve(
        const BrazilMapPreferredViewportRequest(
          userHasManualMapViewport: true,
          cachedBindingKey: '__brazil__',
          regionBindingKey: '__brazil__',
          selectedStoreId: null,
          selectedPoint: selectedPoint,
          shouldFocusCameraOnSelectedStore: true,
          selectedStoreZoomLevel: 5,
          activeRegionKey: null,
        ),
      );

      expect(result.viewport, isNull);
      expect(result.bindingKeyToRecord, isNull);
    });

    test('focuses selected store when requested', () {
      final result = BrazilMapPreferredViewportPolicy.resolve(
        const BrazilMapPreferredViewportRequest(
          userHasManualMapViewport: false,
          cachedBindingKey: null,
          regionBindingKey: '__brazil__',
          selectedStoreId: 'store-1',
          selectedPoint: selectedPoint,
          shouldFocusCameraOnSelectedStore: true,
          selectedStoreZoomLevel: 4.5,
          activeRegionKey: null,
        ),
      );

      expect(result.viewport?.centerLatitude, selectedPoint.latitude);
      expect(result.viewport?.centerLongitude, selectedPoint.longitude);
      expect(result.viewport?.zoomLevel, 4.5);
      expect(result.bindingKeyToRecord, isNull);
    });

    test('returns null while selected store id is set without focus', () {
      final result = BrazilMapPreferredViewportPolicy.resolve(
        const BrazilMapPreferredViewportRequest(
          userHasManualMapViewport: false,
          cachedBindingKey: null,
          regionBindingKey: '__brazil__',
          selectedStoreId: 'store-1',
          selectedPoint: selectedPoint,
          shouldFocusCameraOnSelectedStore: false,
          selectedStoreZoomLevel: 4.5,
          activeRegionKey: null,
        ),
      );

      expect(result.viewport, isNull);
    });

    test('returns null when binding key already matches region', () {
      final result = BrazilMapPreferredViewportPolicy.resolve(
        const BrazilMapPreferredViewportRequest(
          userHasManualMapViewport: false,
          cachedBindingKey: 'SP',
          regionBindingKey: 'SP',
          selectedStoreId: null,
          selectedPoint: null,
          shouldFocusCameraOnSelectedStore: false,
          selectedStoreZoomLevel: 3,
          activeRegionKey: 'SP',
        ),
      );

      expect(result.viewport, isNull);
    });

    test('returns region viewport and binding key for new scope', () {
      final result = BrazilMapPreferredViewportPolicy.resolve(
        const BrazilMapPreferredViewportRequest(
          userHasManualMapViewport: false,
          cachedBindingKey: '__brazil__',
          regionBindingKey: 'CO',
          selectedStoreId: null,
          selectedPoint: null,
          shouldFocusCameraOnSelectedStore: false,
          selectedStoreZoomLevel: 3,
          activeRegionKey: 'CO',
        ),
      );

      expect(
        result.viewport,
        AppBrazilMapStaticData.regionViewports['CO'],
      );
      expect(result.bindingKeyToRecord, 'CO');
    });
  });

  group('BrazilMapViewportCoordinator', () {
    test('resetManualViewport clears manual flag and cached viewport', () {
      final coordinator = BrazilMapViewportCoordinator()
        ..userHasManualMapViewport = true
        ..cachedPreferredViewport = AppBrazilMapStaticData.brazilViewport
        ..cachedPreferredViewportBinding = '__brazil__'
        ..resetManualViewport();

      expect(coordinator.userHasManualMapViewport, isFalse);
      expect(coordinator.cachedPreferredViewport, isNull);
      expect(coordinator.cachedPreferredViewportBinding, isNull);
    });

    test('regionBindingKey defaults to brazil sentinel', () {
      final coordinator = BrazilMapViewportCoordinator();
      expect(coordinator.regionBindingKey(null), '__brazil__');
      expect(coordinator.regionBindingKey('RJ'), 'RJ');
    });

    test('resetTargetViewportForScope resolves region or Brazil default', () {
      final coordinator = BrazilMapViewportCoordinator();

      expect(
        coordinator.resetTargetViewportForScope(null),
        AppBrazilMapStaticData.brazilViewport,
      );
      expect(
        coordinator.resetTargetViewportForScope('CO'),
        AppBrazilMapStaticData.regionViewports['CO'],
      );
    });

    test('defers cluster zoom until pointer gesture ends', () {
      final coordinator = BrazilMapViewportCoordinator();
      final appliedZoomLevels = <double>[];
      final zoom = BrazilMapZoomController(initialClusteringZoom: 2);
      const event = AppMapViewportChangedEvent(
        viewport: AppMapViewport(
          centerLatitude: -15,
          centerLongitude: -56,
          zoomLevel: 3.5,
        ),
      );

      coordinator
        ..handleMapPointerDown(deferDuringGesture: true)
        ..handleViewportChanged(
          event: event,
          enableProximityCluster: true,
          blocksViewportDrivenClustering: false,
          enableZoomPan: true,
          zoom: zoom,
          onMarkManualViewport: () {},
          shouldClearStoreDetailOnUserViewportChange: false,
          onClearStoreDetail: () {},
          onApplyClusterZoom: appliedZoomLevels.add,
          pointCount: 10,
          activeRegionKey: null,
        );
      expect(appliedZoomLevels, isEmpty);

      coordinator.handleMapPointerUp(
        deferDuringGesture: true,
        onApplyClusterZoom: appliedZoomLevels.add,
      );

      expect(appliedZoomLevels, <double>[3.5]);
    });

    test(
      'cancelPendingViewportClusterSampling clears pending gesture state',
      () {
        final coordinator = BrazilMapViewportCoordinator();
        final appliedZoomLevels = <double>[];
        coordinator
          ..handleMapPointerDown(deferDuringGesture: true)
          ..cancelPendingViewportClusterSampling()
          ..handleMapPointerUp(
            deferDuringGesture: true,
            onApplyClusterZoom: appliedZoomLevels.add,
          );

        expect(appliedZoomLevels, isEmpty);
      },
    );
  });
}
