import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/region_map_viewport_sync_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegionMapViewportController', () {
    test('withdrawPreferredViewportForStoreSelection sets suppress flag', () {
      final controller = RegionMapViewportController();
      expect(controller.suppressPreferredViewport, isFalse);

      controller.withdrawPreferredViewportForStoreSelection();

      expect(controller.suppressPreferredViewport, isTrue);
      controller.reset();
      expect(controller.suppressPreferredViewport, isFalse);
    });
  });

  group('RegionMapViewportSyncPolicy', () {
    test('shouldShowResetViewportButton when preferred or manual viewport', () {
      expect(
        RegionMapViewportSyncPolicy.shouldShowResetViewportButton(
          hasPreferredViewport: true,
          userHasManualViewport: false,
        ),
        isTrue,
      );
      expect(
        RegionMapViewportSyncPolicy.shouldShowResetViewportButton(
          hasPreferredViewport: false,
          userHasManualViewport: true,
        ),
        isTrue,
      );
      expect(
        RegionMapViewportSyncPolicy.shouldShowResetViewportButton(
          hasPreferredViewport: false,
          userHasManualViewport: false,
        ),
        isFalse,
      );
    });

    test(
      'allowsPointerWheelZoom stays enabled when preferred viewport is suppressed',
      () {
        final controller = RegionMapViewportController()
          ..withdrawPreferredViewportForStoreSelection();
        expect(controller.suppressPreferredViewport, isTrue);
        expect(
          RegionMapViewportSyncPolicy.allowsPointerWheelZoom(
            isZoomPanEnabled: true,
          ),
          isTrue,
        );
        expect(
          RegionMapViewportSyncPolicy.allowsPointerWheelZoom(
            isZoomPanEnabled: false,
          ),
          isFalse,
        );
      },
    );

    test(
      'shouldSyncZoomPanBehaviorOnWidgetUpdate is false when behavior matches state',
      () {
        expect(
          RegionMapViewportSyncPolicy.shouldSyncZoomPanBehaviorOnWidgetUpdate(
            hasPreferredViewport: true,
            userHasManualViewport: false,
            lockPreferredViewportReapply: false,
            behaviorZoomLevel: 1.45,
            behaviorCenterLatitude: -14.235,
            behaviorCenterLongitude: -51.9253,
            stateZoomLevel: 1.45,
            stateCenterLatitude: -14.235,
            stateCenterLongitude: -51.9253,
          ),
          isFalse,
        );
      },
    );

    test(
      'shouldSyncZoomPanBehaviorOnWidgetUpdate is false when user has manual viewport',
      () {
        expect(
          RegionMapViewportSyncPolicy.shouldSyncZoomPanBehaviorOnWidgetUpdate(
            hasPreferredViewport: true,
            userHasManualViewport: true,
            lockPreferredViewportReapply: false,
            behaviorZoomLevel: 1,
            behaviorCenterLatitude: null,
            behaviorCenterLongitude: null,
            stateZoomLevel: 2,
            stateCenterLatitude: null,
            stateCenterLongitude: null,
          ),
          isFalse,
        );
      },
    );

    test(
      'shouldSyncZoomPanBehaviorOnWidgetUpdate is false when preferred viewport is locked',
      () {
        expect(
          RegionMapViewportSyncPolicy.shouldSyncZoomPanBehaviorOnWidgetUpdate(
            hasPreferredViewport: true,
            userHasManualViewport: false,
            lockPreferredViewportReapply: true,
            behaviorZoomLevel: 1.45,
            behaviorCenterLatitude: -14.235,
            behaviorCenterLongitude: -51.9253,
            stateZoomLevel: 1.8,
            stateCenterLatitude: -14.235,
            stateCenterLongitude: -51.9253,
          ),
          isFalse,
        );
      },
    );

    test(
      'shouldSyncZoomPanBehaviorOnWidgetUpdate is true when zoom drifts from state',
      () {
        expect(
          RegionMapViewportSyncPolicy.shouldSyncZoomPanBehaviorOnWidgetUpdate(
            hasPreferredViewport: true,
            userHasManualViewport: false,
            lockPreferredViewportReapply: false,
            behaviorZoomLevel: 1.45,
            behaviorCenterLatitude: -14.235,
            behaviorCenterLongitude: -51.9253,
            stateZoomLevel: 1.8,
            stateCenterLatitude: -14.235,
            stateCenterLongitude: -51.9253,
          ),
          isTrue,
        );
      },
    );

    test(
      'zoomPanBehaviorDriftsFromViewportState detects center drift',
      () {
        expect(
          RegionMapViewportSyncPolicy.zoomPanBehaviorDriftsFromViewportState(
            behaviorZoomLevel: 1.45,
            behaviorCenterLatitude: -14.235,
            behaviorCenterLongitude: -51.9253,
            stateZoomLevel: 1.45,
            stateCenterLatitude: -15,
            stateCenterLongitude: -51.9253,
          ),
          isTrue,
        );
      },
    );

    test(
      'shouldApplyPreferredViewportOnWidgetUpdate ignores equal preferred values',
      () {
        const viewport = AppMapViewport(
          zoomLevel: 1.45,
          centerLatitude: -14.235,
          centerLongitude: -51.9253,
        );
        expect(
          RegionMapViewportSyncPolicy.shouldApplyPreferredViewportOnWidgetUpdate(
            previousPreferred: viewport,
            nextPreferred: viewport,
            userHasManualViewport: false,
            forcePreferredViewport: false,
          ),
          isFalse,
        );
      },
    );

    test(
      'shouldApplyPreferredViewportOnWidgetUpdate skips manual unless forced',
      () {
        const previous = AppMapViewport(
          zoomLevel: 1.45,
          centerLatitude: -14.235,
          centerLongitude: -51.9253,
        );
        const next = AppMapViewport(
          zoomLevel: 2.2,
          centerLatitude: -14.6229,
          centerLongitude: -57.4933,
        );
        expect(
          RegionMapViewportSyncPolicy.shouldApplyPreferredViewportOnWidgetUpdate(
            previousPreferred: previous,
            nextPreferred: next,
            userHasManualViewport: true,
            forcePreferredViewport: false,
          ),
          isFalse,
        );
        expect(
          RegionMapViewportSyncPolicy.shouldApplyPreferredViewportOnWidgetUpdate(
            previousPreferred: previous,
            nextPreferred: next,
            userHasManualViewport: true,
            forcePreferredViewport: true,
          ),
          isTrue,
        );
      },
    );
  });
}
