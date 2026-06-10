import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/brazil_map_snapshot_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const point = AppBrazilStoreSalesPoint(
    id: 'store-1',
    name: 'Store',
    uf: 'MT',
    latitude: -15.6,
    longitude: -56.1,
    salesAmount: 100,
    salesCount: 1,
  );

  group('BrazilMapSnapshotController', () {
    test('resolvePointsDigest caches digest for identical list reference', () {
      final controller = BrazilMapSnapshotController();
      final points = <AppBrazilStoreSalesPoint>[point];

      final first = controller.resolvePointsDigest(points);
      final second = controller.resolvePointsDigest(points);

      expect(second, first);
    });

    test(
      'invalidatePointsDigestIfSourceChanged recomputes after list mutation',
      () {
        final controller = BrazilMapSnapshotController();
        final points = <AppBrazilStoreSalesPoint>[point];
        final before = controller.resolvePointsDigest(points);

        controller.invalidatePointsDigestIfSourceChanged(points);
        points.add(
          const AppBrazilStoreSalesPoint(
            id: 'store-2',
            name: 'Store 2',
            uf: 'SP',
            latitude: -23.5,
            longitude: -46.6,
            salesAmount: 50,
            salesCount: 1,
          ),
        );
        final after = controller.resolvePointsDigest(points);

        expect(after, isNot(equals(before)));
      },
    );

    test('invalidateData clears snapshot caches', () {
      final controller = BrazilMapSnapshotController()..invalidateData();

      expect(controller.snapshotData, isNull);
      expect(controller.snapshot, isNull);
    });

    test('invalidateVisual clears only visual snapshot', () {
      final controller = BrazilMapSnapshotController()..invalidateVisual();

      expect(controller.snapshot, isNull);
    });

    test('computeDataReuseKey changes when points content changes', () {
      final controller = BrazilMapSnapshotController();
      const style = AppBrazilStoreSalesMapStyle();
      const metric = AppBrazilStoreSalesMapMetric.revenue;
      final pointsA = <AppBrazilStoreSalesPoint>[point];
      final pointsB = <AppBrazilStoreSalesPoint>[
        const AppBrazilStoreSalesPoint(
          id: 'store-2',
          name: 'Store 2',
          uf: 'SP',
          latitude: -23.5,
          longitude: -46.6,
          salesAmount: 50,
          salesCount: 1,
        ),
      ];

      final keyA = controller.computeDataReuseKey(
        points: pointsA,
        fixedBranchIds: const <String>{},
        filterBranchIds: const <String>{},
        style: style,
        metric: metric,
        activeRegionKey: null,
        zoomLevel: 2,
        includeVisibleBranchListItems: false,
      );
      final keyB = controller.computeDataReuseKey(
        points: pointsB,
        fixedBranchIds: const <String>{},
        filterBranchIds: const <String>{},
        style: style,
        metric: metric,
        activeRegionKey: null,
        zoomLevel: 2,
        includeVisibleBranchListItems: false,
      );

      expect(keyA, isNot(equals(keyB)));
    });
  });
}
