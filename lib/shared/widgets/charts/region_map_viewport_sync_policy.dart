import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';

/// Mutable hook so store marker taps can withdraw preferred viewport without
/// rebuilding the region map widget tree.
class RegionMapViewportController {
  bool suppressPreferredViewport = false;

  void withdrawPreferredViewportForStoreSelection() {
    suppressPreferredViewport = true;
  }

  void reset() {
    suppressPreferredViewport = false;
  }
}

/// Pure viewport drift checks for the Syncfusion region map update/sync paths.
abstract final class RegionMapViewportSyncPolicy {
  /// Whether the "Centralizar mapa" control should be visible.
  ///
  /// Shown when a programmatic target exists or the user has panned/zoomed
  /// manually (including when the programmatic target is withheld).
  static bool shouldShowResetViewportButton({
    required bool hasPreferredViewport,
    required bool userHasManualViewport,
  }) {
    return hasPreferredViewport || userHasManualViewport;
  }

  /// Programmatic preferred viewport suppression (store selection freeze fix)
  /// must not block pointer-wheel zoom; only programmatic apply paths.
  static bool allowsPointerWheelZoom({
    required bool isZoomPanEnabled,
  }) {
    return isZoomPanEnabled;
  }

  /// Pinch/pan hooks from Syncfusion always represent user intent, even on the
  /// first gesture before manual viewport state is recorded.
  static AppMapViewportChangeSource changeSourceForUserPinchOrPan() {
    return AppMapViewportChangeSource.user;
  }

  static bool zoomPanBehaviorDriftsFromViewportState({
    required double behaviorZoomLevel,
    required double? behaviorCenterLatitude,
    required double? behaviorCenterLongitude,
    required double stateZoomLevel,
    required double? stateCenterLatitude,
    required double? stateCenterLongitude,
  }) {
    if ((behaviorZoomLevel - stateZoomLevel).abs() >=
        BrazilMapLayoutConstants.preferredViewportZoomEpsilon) {
      return true;
    }

    if (stateCenterLatitude == null ||
        stateCenterLongitude == null ||
        behaviorCenterLatitude == null ||
        behaviorCenterLongitude == null) {
      return stateCenterLatitude != behaviorCenterLatitude ||
          stateCenterLongitude != behaviorCenterLongitude;
    }

    return (behaviorCenterLatitude - stateCenterLatitude).abs() >=
            BrazilMapLayoutConstants.preferredViewportCenterEpsilon ||
        (behaviorCenterLongitude - stateCenterLongitude).abs() >=
            BrazilMapLayoutConstants.preferredViewportCenterEpsilon;
  }

  static bool shouldSyncZoomPanBehaviorOnWidgetUpdate({
    required bool hasPreferredViewport,
    required bool userHasManualViewport,
    required bool lockPreferredViewportReapply,
    required double behaviorZoomLevel,
    required double? behaviorCenterLatitude,
    required double? behaviorCenterLongitude,
    required double stateZoomLevel,
    required double? stateCenterLatitude,
    required double? stateCenterLongitude,
  }) {
    if (!hasPreferredViewport ||
        userHasManualViewport ||
        lockPreferredViewportReapply) {
      return false;
    }

    return zoomPanBehaviorDriftsFromViewportState(
      behaviorZoomLevel: behaviorZoomLevel,
      behaviorCenterLatitude: behaviorCenterLatitude,
      behaviorCenterLongitude: behaviorCenterLongitude,
      stateZoomLevel: stateZoomLevel,
      stateCenterLatitude: stateCenterLatitude,
      stateCenterLongitude: stateCenterLongitude,
    );
  }

  /// Whether the next preferred viewport should drive Syncfusion after rebuild.
  ///
  /// A genuinely new preferred target (scope change, one-shot store focus) may
  /// still apply while the reapply lock is set; the lock only blocks drift sync.
  static bool shouldApplyPreferredViewportOnWidgetUpdate({
    required AppMapViewport? previousPreferred,
    required AppMapViewport? nextPreferred,
    required bool userHasManualViewport,
    bool forcePreferredViewport = false,
  }) {
    if (nextPreferred == null) {
      return false;
    }
    if (previousPreferred == nextPreferred) {
      return false;
    }
    if (userHasManualViewport && !forcePreferredViewport) {
      return false;
    }
    return true;
  }
}
