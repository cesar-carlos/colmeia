import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_layout_constants.dart';

/// Separates clustering zoom (proximity cluster sampling for snapshot data)
/// from camera zoom, which the chart resolves via map viewport/style.
class BrazilMapZoomController {
  BrazilMapZoomController({double? initialClusteringZoom})
    : clusteringZoomLevel =
          initialClusteringZoom ??
          AppBrazilMapStaticData.brazilViewport.zoomLevel;

  double clusteringZoomLevel;

  void resetToBrazilDefault() {
    clusteringZoomLevel = AppBrazilMapStaticData.brazilViewport.zoomLevel;
  }

  void applyScopeZoom(double? scopeZoomLevel) {
    clusteringZoomLevel =
        scopeZoomLevel ?? AppBrazilMapStaticData.brazilViewport.zoomLevel;
  }

  bool shouldApplyViewportClusterSample(
    double nextZoomLevel, {
    required bool blocksViewportDrivenClustering,
  }) {
    if (blocksViewportDrivenClustering) {
      return false;
    }
    return (nextZoomLevel - clusteringZoomLevel).abs() >=
        BrazilMapLayoutConstants.viewportClusterZoomEpsilon;
  }
}
