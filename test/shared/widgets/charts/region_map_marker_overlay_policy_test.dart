import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/region_map_marker_overlay_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegionMapMarkerOverlayPolicy', () {
    test('defers markers while the shape layer is not ready', () {
      expect(
        RegionMapMarkerOverlayPolicy.shouldDeferMarkers(
          isLoading: false,
          markersOverlayReady: false,
          pointCount: 3,
          itemCount: 2,
        ),
        isTrue,
      );
    });

    test('does not defer markers once the overlay is ready', () {
      expect(
        RegionMapMarkerOverlayPolicy.shouldDeferMarkers(
          isLoading: false,
          markersOverlayReady: true,
          pointCount: 3,
          itemCount: 2,
        ),
        isFalse,
      );
    });

    test('does not defer while the map surface is loading', () {
      expect(
        RegionMapMarkerOverlayPolicy.shouldDeferMarkers(
          isLoading: true,
          markersOverlayReady: false,
          pointCount: 3,
          itemCount: 2,
        ),
        isFalse,
      );
    });

    test('does not defer when there are no markers', () {
      expect(
        RegionMapMarkerOverlayPolicy.shouldDeferMarkers(
          isLoading: false,
          markersOverlayReady: false,
          pointCount: 0,
          itemCount: 2,
        ),
        isFalse,
      );
    });

    test('effectivePoints returns empty list while deferring', () {
      const points = <AppMapPoint>[
        AppMapPoint(latitude: -23, longitude: -46),
      ];

      expect(
        RegionMapMarkerOverlayPolicy.effectivePoints(
          points: points,
          deferMarkers: true,
        ),
        isEmpty,
      );
      expect(
        RegionMapMarkerOverlayPolicy.effectivePoints(
          points: points,
          deferMarkers: false,
        ),
        same(points),
      );
    });

    test(
      'mapSurfaceKeyFingerprint changes when marker mount generation bumps',
      () {
        const geometryFingerprint = 42;

        final initialKey =
            RegionMapMarkerOverlayPolicy.mapSurfaceKeyFingerprint(
              geometryFingerprint: geometryFingerprint,
              markerOverlayMountGeneration: 0,
            );
        final readyKey = RegionMapMarkerOverlayPolicy.mapSurfaceKeyFingerprint(
          geometryFingerprint: geometryFingerprint,
          markerOverlayMountGeneration: 1,
        );

        expect(initialKey, isNot(readyKey));
        expect(
          RegionMapMarkerOverlayPolicy.mapSurfaceKeyFingerprint(
            geometryFingerprint: geometryFingerprint,
            markerOverlayMountGeneration: 1,
          ),
          readyKey,
        );
      },
    );
  });
}
