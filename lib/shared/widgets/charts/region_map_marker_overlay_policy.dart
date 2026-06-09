import 'package:colmeia/shared/widgets/charts/app_map_models.dart';

/// Pure rules for deferring marker overlays until the region shape layer has
/// had a chance to paint on the Syncfusion map surface.
abstract final class RegionMapMarkerOverlayPolicy {
  /// True while marker payloads should be withheld from the map shape layer.
  ///
  /// Markers are deferred only when the map is actively rendering regions
  /// (itemCount > 0, not loading) but the shape layer has not yet been
  /// acknowledged as painted (markersOverlayReady is false).
  static bool shouldDeferMarkers({
    required bool isLoading,
    required bool markersOverlayReady,
    required int pointCount,
    required int itemCount,
  }) {
    if (isLoading || itemCount <= 0) {
      return false;
    }
    return pointCount > 0 && !markersOverlayReady;
  }

  /// Marker list passed to the map engine while deferring is active.
  static List<AppMapPoint> effectivePoints({
    required List<AppMapPoint> points,
    required bool deferMarkers,
  }) {
    if (!deferMarkers) {
      return points;
    }
    return const <AppMapPoint>[];
  }

  /// Syncfusion map surface key fingerprint. markerOverlayMountGeneration bumps
  /// only when a deferred marker payload becomes ready so the map remounts with
  /// the correct initial marker count without remounting on every deferral frame
  /// or routine marker updates.
  static int mapSurfaceKeyFingerprint({
    required int geometryFingerprint,
    required int markerOverlayMountGeneration,
  }) {
    return Object.hash(geometryFingerprint, markerOverlayMountGeneration);
  }
}
