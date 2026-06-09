import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/app_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_chart_visual_snapshot.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_marker_selection_controller.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_selection_policy.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pointA = AppBrazilStoreSalesPoint(
    id: 'store-a',
    name: 'Store A',
    uf: 'MT',
    latitude: -15.6,
    longitude: -56.1,
    salesAmount: 100,
    salesCount: 1,
  );
  const pointB = AppBrazilStoreSalesPoint(
    id: 'store-b',
    name: 'Store B',
    uf: 'SP',
    latitude: -23.5,
    longitude: -46.6,
    salesAmount: 50,
    salesCount: 1,
  );
  const mtBucket = AppBrazilStoreSalesStateBucket(
    uf: 'MT',
    stateName: 'Mato Grosso',
    regionKey: 'MT',
    regionName: 'Mato Grosso',
    salesAmount: 100,
    salesCount: 1,
    storeCount: 1,
  );

  group('BrazilMapMarkerSelectionController', () {
    test('publishWithControlledId prefers controlled store id', () {
      final controller = BrazilMapMarkerSelectionController();
      final selection = BrazilMapSelectionPolicy()
        ..internalSelectedStoreId = 'internal-store'
        ..internalSelectedStateKey = 'MT';

      controller.publishWithControlledId(selection, 'controlled-store');

      expect(controller.notifier.value.selectedStoreId, 'controlled-store');
      expect(controller.notifier.value.shapeHighlightRegionKey, 'MT');
    });

    test('publishWithControlledId falls back to internal selection', () {
      final controller = BrazilMapMarkerSelectionController();
      final selection = BrazilMapSelectionPolicy()
        ..internalSelectedStoreId = 'internal-store'
        ..internalSelectedStateKey = 'SP';

      controller.publishWithControlledId(selection, null);

      expect(controller.notifier.value.selectedStoreId, 'internal-store');
      expect(controller.notifier.value.shapeHighlightRegionKey, 'SP');
    });

    test('clearPreviewedPoint defers clearing preview on desktop delay', () {
      fakeAsync((async) {
        final controller = BrazilMapMarkerSelectionController();
        final selection = BrazilMapSelectionPolicy();
        var changeCount = 0;

        controller
          ..previewBranchForTesting(pointA)
          ..clearPreviewedPoint(
            selection: selection,
            controlledSelectedStoreId: null,
            onChanged: () => changeCount++,
          );

        expect(controller.previewedStoreId, pointA.id);
        expect(changeCount, 0);

        async.elapse(BrazilMapMarkerSelectionController.desktopPreviewClearDelay);

        expect(controller.previewedStoreId, isNull);
        expect(changeCount, 1);
        expect(controller.notifier.value.previewedStoreId, isNull);
      });
    });

    test('cancelPendingPreviewClear keeps preview until explicit clear', () {
      fakeAsync((async) {
        final controller = BrazilMapMarkerSelectionController();
        final selection = BrazilMapSelectionPolicy();

        controller
          ..previewBranchForTesting(pointA)
          ..clearPreviewedPoint(
            selection: selection,
            controlledSelectedStoreId: null,
            onChanged: () {},
          )
          ..cancelPendingPreviewClear();

        async.elapse(BrazilMapMarkerSelectionController.desktopPreviewClearDelay);

        expect(controller.previewedStoreId, pointA.id);
      });
    });
  });

  group('BrazilMapMarkerSelectionController.resolveSelectedStateBucket', () {
    test('returns null when no highlight key is available', () {
      final snapshot = _visualSnapshot(
        buckets: const <AppBrazilStoreSalesStateBucket>[mtBucket],
      );

      final bucket = BrazilMapMarkerSelectionController.resolveSelectedStateBucket(
        snapshot,
        const BrazilMapMarkerSelection(),
      );

      expect(bucket, isNull);
    });

    test('returns bucket matching selection shape highlight key', () {
      final snapshot = _visualSnapshot(
        buckets: const <AppBrazilStoreSalesStateBucket>[mtBucket],
      );

      final bucket = BrazilMapMarkerSelectionController.resolveSelectedStateBucket(
        snapshot,
        const BrazilMapMarkerSelection(shapeHighlightRegionKey: 'MT'),
      );

      expect(bucket, mtBucket);
    });

    test('falls back to snapshot selected state key', () {
      final snapshot = _visualSnapshot(
        buckets: const <AppBrazilStoreSalesStateBucket>[mtBucket],
        selectedStateKey: 'MT',
      );

      final bucket = BrazilMapMarkerSelectionController.resolveSelectedStateBucket(
        snapshot,
        const BrazilMapMarkerSelection(),
      );

      expect(bucket, mtBucket);
    });
  });

  group('BrazilMapMarkerSelectionController.resolveMarkerDetailSelection', () {
    test('returns empty selection when selected store id is null', () {
      final snapshot = _visualSnapshot(
        markerGroups: <AppBrazilStoreSalesMarkerGroup>[
          AppBrazilStoreSalesMarkerGroup(points: <AppBrazilStoreSalesPoint>[pointA]),
        ],
      );

      final result = BrazilMapMarkerSelectionController.resolveMarkerDetailSelection(
        snapshot,
        const BrazilMapMarkerSelection(),
        (id) => id == pointA.id ? pointA : null,
      );

      expect(result.point, isNull);
      expect(result.group, isNull);
    });

    test('resolves point and group from snapshot and lookup', () {
      final group = AppBrazilStoreSalesMarkerGroup(
        points: <AppBrazilStoreSalesPoint>[pointA, pointB],
      );
      final snapshot = _visualSnapshot(
        markerGroups: <AppBrazilStoreSalesMarkerGroup>[group],
        selectedPoint: pointA,
        selectedMarkerGroup: group,
      );

      final result = BrazilMapMarkerSelectionController.resolveMarkerDetailSelection(
        snapshot,
        const BrazilMapMarkerSelection(selectedStoreId: 'store-a'),
        (id) => id == pointA.id ? pointA : null,
      );

      expect(result.point, pointA);
      expect(result.group, group);
    });

    test('synthesizes single-point group when only point is known', () {
      final snapshot = _visualSnapshot();

      final result = BrazilMapMarkerSelectionController.resolveMarkerDetailSelection(
        snapshot,
        const BrazilMapMarkerSelection(selectedStoreId: 'store-b'),
        (id) => id == pointB.id ? pointB : null,
      );

      expect(result.point, pointB);
      expect(result.group?.points, <AppBrazilStoreSalesPoint>[pointB]);
    });
  });
}

BrazilMapChartVisualSnapshot _visualSnapshot({
  List<AppBrazilStoreSalesStateBucket> buckets = const <AppBrazilStoreSalesStateBucket>[],
  List<AppBrazilStoreSalesMarkerGroup> markerGroups =
      const <AppBrazilStoreSalesMarkerGroup>[],
  AppBrazilStoreSalesPoint? selectedPoint,
  AppBrazilStoreSalesMarkerGroup? selectedMarkerGroup,
  String? selectedStateKey,
  AppBrazilStoreSalesStateBucket? selectedStateBucket,
}) {
  final resolvedStateBucket = selectedStateBucket ??
      (selectedStateKey == null
          ? null
          : buckets.where((bucket) => bucket.uf == selectedStateKey).firstOrNull);
  final data = AppBrazilStoreSalesMapSnapshotData(
    metric: AppBrazilStoreSalesMapMetric.revenue,
    selectedStoreId: selectedPoint?.id,
    requestedStateKey: selectedStateKey,
    activeRegionKey: selectedStateKey,
    zoomLevel: 2,
    visiblePoints: selectedPoint == null
        ? const <AppBrazilStoreSalesPoint>[]
        : <AppBrazilStoreSalesPoint>[selectedPoint],
    visibleBranchListItems: const <AppBrazilStoreSalesVisibleBranchListItem>[],
    buckets: buckets,
    markerGroups: markerGroups,
    stateBubbleBuckets: buckets,
    selectedPoint: selectedPoint,
    selectedMarkerGroup: selectedMarkerGroup,
    selectedStateKey: selectedStateKey,
    selectedStateBucket: resolvedStateBucket,
    minMarkerValue: 0,
    maxMarkerValue: 1,
    diagnostics: const AppBrazilStoreSalesMapDiagnostics(
      totalPointCount: 0,
      validPointCount: 0,
      invalidCoordinateCount: 0,
      unknownUfCount: 0,
      filteredByRegionCount: 0,
    ),
    validPointCount: 0,
    cachedReuseKey: 'test',
  );

  return BrazilMapChartVisualSnapshot(
    data: data,
    mapPoints: const <AppMapPoint>[],
    visualReuseKey: 'test',
    selectedStoreId: selectedPoint?.id,
    requestedStateKey: selectedStateKey,
    selectedPoint: selectedPoint,
    selectedMarkerGroup: selectedMarkerGroup,
    selectedStateKey: selectedStateKey,
    selectedStateBucket: resolvedStateBucket,
  );
}
