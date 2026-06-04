import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_zoom_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrazilMapZoomController', () {
    test('initializes to Brazil default zoom', () {
      final controller = BrazilMapZoomController();
      expect(
        controller.clusteringZoomLevel,
        AppBrazilMapStaticData.brazilViewport.zoomLevel,
      );
    });

    test('clusteringZoomLevel can be updated for store selection', () {
      final controller = BrazilMapZoomController()..clusteringZoomLevel = 4.2;
      expect(controller.clusteringZoomLevel, 4.2);
    });

    test('shouldApplyViewportClusterSample respects block flag', () {
      final controller = BrazilMapZoomController();
      expect(
        controller.shouldApplyViewportClusterSample(
          5,
          blocksViewportDrivenClustering: true,
        ),
        isFalse,
      );
      expect(
        controller.shouldApplyViewportClusterSample(
          5,
          blocksViewportDrivenClustering: false,
        ),
        isTrue,
      );
    });

    test('shouldApplyViewportClusterSample ignores small deltas', () {
      final controller = BrazilMapZoomController(initialClusteringZoom: 2);
      expect(
        controller.shouldApplyViewportClusterSample(
          2.1,
          blocksViewportDrivenClustering: false,
        ),
        isFalse,
      );
    });
  });
}
