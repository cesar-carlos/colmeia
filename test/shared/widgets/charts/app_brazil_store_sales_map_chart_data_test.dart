import 'dart:convert';
import 'dart:io';

import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBrazilStoreSalesMapData', () {
    test('normalizes UF with trim and uppercase', () {
      expect(AppBrazilStoreSalesMapData.normalizeUf(' mt '), 'MT');
      expect(AppBrazilStoreSalesMapData.normalizeUf('sp'), 'SP');
    });

    test('aggregates state buckets by revenue and sales count', () {
      final buckets = AppBrazilStoreSalesMapData.buildStateBuckets(
        const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'sinop',
            name: 'Loja Sinop',
            uf: ' mt ',
            latitude: -11.8604,
            longitude: -55.5091,
            salesAmount: 150.75,
            salesCount: 2,
          ),
          AppBrazilStoreSalesPoint(
            id: 'cuiaba',
            name: 'Loja Cuiaba',
            uf: 'MT',
            latitude: -15.6014,
            longitude: -56.0979,
            salesAmount: 200,
            salesCount: 3,
          ),
          AppBrazilStoreSalesPoint(
            id: 'goiania',
            name: 'Loja Goiania',
            uf: 'GO',
            latitude: -16.6869,
            longitude: -49.2648,
            salesAmount: 90,
            salesCount: 1,
          ),
        ],
        includeEmptyStates: false,
      );

      final mt = buckets.singleWhere((bucket) => bucket.uf == 'MT');
      final go = buckets.singleWhere((bucket) => bucket.uf == 'GO');

      expect(mt.salesAmount, 350.75);
      expect(mt.salesCount, 5);
      expect(mt.storeCount, 2);
      expect(go.salesAmount, 90);
      expect(go.salesCount, 1);
      expect(AppBrazilStoreSalesMapMetric.revenue.valueForBucket(mt), 350.75);
      expect(AppBrazilStoreSalesMapMetric.salesCount.valueForBucket(mt), 5);
    });

    test(
      'keeps national buckets with zero values for states without sales',
      () {
        final buckets = AppBrazilStoreSalesMapData.buildStateBuckets(
          const <AppBrazilStoreSalesPoint>[
            AppBrazilStoreSalesPoint(
              id: 'paulista',
              name: 'Loja Paulista',
              uf: 'SP',
              latitude: -23.5505,
              longitude: -46.6333,
              salesAmount: 1000,
              salesCount: 10,
            ),
          ],
        );

        expect(buckets, hasLength(AppBrazilMapStaticData.ufCodes.length));

        final acre = buckets.singleWhere((bucket) => bucket.uf == 'AC');
        final saoPaulo = buckets.singleWhere((bucket) => bucket.uf == 'SP');

        expect(acre.salesAmount, 0);
        expect(acre.salesCount, 0);
        expect(acre.storeCount, 0);
        expect(saoPaulo.salesAmount, 1000);
        expect(saoPaulo.salesCount, 10);
        expect(saoPaulo.storeCount, 1);
      },
    );

    test('calculates marker size for equal, minimum and maximum values', () {
      expect(
        AppBrazilStoreSalesMapData.markerSizeFor(
          value: 10,
          minValue: 10,
          maxValue: 10,
          minSize: 8,
          maxSize: 20,
        ),
        14,
      );
      expect(
        AppBrazilStoreSalesMapData.markerSizeFor(
          value: 10,
          minValue: 10,
          maxValue: 100,
          minSize: 8,
          maxSize: 20,
        ),
        8,
      );
      expect(
        AppBrazilStoreSalesMapData.markerSizeFor(
          value: 100,
          minValue: 10,
          maxValue: 100,
          minSize: 8,
          maxSize: 20,
        ),
        20,
      );
    });

    test('discards map points with invalid coordinates or unknown UF', () {
      final points = AppBrazilStoreSalesMapData.validMapPoints(
        <AppBrazilStoreSalesPoint>[
          const AppBrazilStoreSalesPoint(
            id: 'valid',
            name: 'Loja Valida',
            uf: 'MT',
            latitude: -15,
            longitude: -56,
            salesAmount: 100,
            salesCount: 1,
            locationResolution:
                AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
          ),
          const AppBrazilStoreSalesPoint(
            id: 'bad-latitude',
            name: 'Latitude invalida',
            uf: 'MT',
            latitude: -91,
            longitude: -56,
            salesAmount: 100,
            salesCount: 1,
            locationResolution:
                AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
          ),
          const AppBrazilStoreSalesPoint(
            id: 'bad-longitude',
            name: 'Longitude invalida',
            uf: 'MT',
            latitude: -15,
            longitude: -181,
            salesAmount: 100,
            salesCount: 1,
          ),
          const AppBrazilStoreSalesPoint(
            id: 'bad-uf',
            name: 'UF invalida',
            uf: 'ZZ',
            latitude: -15,
            longitude: -56,
            salesAmount: 100,
            salesCount: 1,
          ),
          const AppBrazilStoreSalesPoint(
            id: 'nan',
            name: 'Coordenada NaN',
            uf: 'MT',
            latitude: double.nan,
            longitude: -56,
            salesAmount: 100,
            salesCount: 1,
          ),
        ],
      );

      expect(points.map((point) => point.id), <String>['valid']);
    });

    test('builds diagnostics for invalid, unknown and filtered points', () {
      const points = <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'valid',
          name: 'Loja Valida',
          uf: 'MT',
          latitude: -15,
          longitude: -56,
          salesAmount: 100,
          salesCount: 1,
          locationResolution:
              AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
        ),
        AppBrazilStoreSalesPoint(
          id: 'bad-coordinate',
          name: 'Coordenada invalida',
          uf: 'MT',
          latitude: -91,
          longitude: -56,
          salesAmount: 100,
          salesCount: 1,
        ),
        AppBrazilStoreSalesPoint(
          id: 'bad-uf',
          name: 'UF invalida',
          uf: 'ZZ',
          latitude: -15,
          longitude: -56,
          salesAmount: 100,
          salesCount: 1,
        ),
        AppBrazilStoreSalesPoint(
          id: 'filtered',
          name: 'Fora do recorte',
          uf: 'SP',
          latitude: -23,
          longitude: -46,
          salesAmount: 100,
          salesCount: 1,
        ),
      ];

      final diagnostics = AppBrazilStoreSalesMapData.buildDiagnostics(
        points,
        regionKey: 'CO',
      );
      final prepared = AppBrazilStoreSalesMapData.prepareSnapshotData(
        points,
        regionKey: 'CO',
      );

      expect(diagnostics.totalPointCount, 4);
      expect(diagnostics.validPointCount, 1);
      expect(diagnostics.invalidCoordinateCount, 1);
      expect(diagnostics.unknownUfCount, 1);
      expect(diagnostics.filteredByRegionCount, 1);
      expect(diagnostics.resolvedByIbgeMunicipalityCodeCount, 1);
      expect(diagnostics.unknownResolutionCount, 0);
      expect(diagnostics.discardedPointCount, 3);
      expect(diagnostics.hasDiscardedPoints, isTrue);
      expect(prepared.diagnostics, diagnostics);
      expect(prepared.validPoints.map((point) => point.id), <String>['valid']);
      expect(
        prepared.buckets.singleWhere((bucket) => bucket.uf == 'MT').storeCount,
        2,
      );
    });

    test('filters buckets and markers by region', () {
      const points = <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'sinop',
          name: 'Loja Sinop',
          uf: 'MT',
          latitude: -11,
          longitude: -55,
          salesAmount: 100,
          salesCount: 1,
        ),
        AppBrazilStoreSalesPoint(
          id: 'paulista',
          name: 'Loja Paulista',
          uf: 'SP',
          latitude: -23,
          longitude: -46,
          salesAmount: 300,
          salesCount: 3,
        ),
      ];

      final buckets = AppBrazilStoreSalesMapData.buildStateBuckets(
        points,
        regionKey: 'CO',
      );
      final markers = AppBrazilStoreSalesMapData.validMapPoints(
        points,
        regionKey: 'CO',
      );

      expect(buckets.map((bucket) => bucket.uf), contains('MT'));
      expect(buckets.map((bucket) => bucket.uf), isNot(contains('SP')));
      expect(markers.map((point) => point.id), <String>['sinop']);
    });

    test('groups stores that share the same rounded coordinate', () {
      final groups = AppBrazilStoreSalesMapData.buildMarkerGroups(
        const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'a',
            name: 'Loja A',
            uf: 'SP',
            latitude: -23.55051,
            longitude: -46.63331,
            salesAmount: 100,
            salesCount: 1,
          ),
          AppBrazilStoreSalesPoint(
            id: 'b',
            name: 'Loja B',
            uf: 'SP',
            latitude: -23.55052,
            longitude: -46.63332,
            salesAmount: 250,
            salesCount: 2,
          ),
          AppBrazilStoreSalesPoint(
            id: 'c',
            name: 'Loja C',
            uf: 'RJ',
            latitude: -22.9068,
            longitude: -43.1729,
            salesAmount: 90,
            salesCount: 1,
          ),
        ],
        coordinatePrecision: 3,
      );

      final cluster = groups.singleWhere((group) => group.uf == 'SP');
      final rio = groups.singleWhere((group) => group.uf == 'RJ');

      expect(cluster.isCluster, isTrue);
      expect(cluster.points.map((point) => point.id), <String>['b', 'a']);
      expect(cluster.salesAmount, 350);
      expect(cluster.salesCount, 3);
      expect(rio.isCluster, isFalse);
    });

    test('groups nearby stores when proximity clustering is enabled', () {
      final groups = AppBrazilStoreSalesMapData.buildMarkerGroups(
        const <AppBrazilStoreSalesPoint>[
          AppBrazilStoreSalesPoint(
            id: 'paulista',
            name: 'Loja Paulista',
            uf: 'SP',
            latitude: -23.5505,
            longitude: -46.6333,
            salesAmount: 100,
            salesCount: 1,
          ),
          AppBrazilStoreSalesPoint(
            id: 'pinheiros',
            name: 'Loja Pinheiros',
            uf: 'SP',
            latitude: -23.5614,
            longitude: -46.6559,
            salesAmount: 250,
            salesCount: 2,
          ),
          AppBrazilStoreSalesPoint(
            id: 'rio',
            name: 'Loja Rio',
            uf: 'RJ',
            latitude: -22.9068,
            longitude: -43.1729,
            salesAmount: 90,
            salesCount: 1,
          ),
        ],
        enableProximityCluster: true,
        proximityClusterDistanceDegrees: 0.05,
      );

      final saoPaulo = groups.singleWhere((group) => group.uf == 'SP');
      final rio = groups.singleWhere((group) => group.uf == 'RJ');

      expect(saoPaulo.isCluster, isTrue);
      expect(saoPaulo.points.map((point) => point.id), <String>[
        'pinheiros',
        'paulista',
      ]);
      expect(rio.isCluster, isFalse);
    });

    test(
      'groups stores by municipality when municipality aggregation is used',
      () {
        final groups = AppBrazilStoreSalesMapData.buildMarkerGroups(
          const <AppBrazilStoreSalesPoint>[
            AppBrazilStoreSalesPoint(
              id: 'sinop-a',
              name: 'Loja Sinop A',
              uf: 'MT',
              municipalityCode: '5107909',
              city: 'Sinop',
              latitude: -11.8604,
              longitude: -55.5091,
              salesAmount: 100,
              salesCount: 1,
            ),
            AppBrazilStoreSalesPoint(
              id: 'sinop-b',
              name: 'Loja Sinop B',
              uf: 'MT',
              municipalityCode: '5107909',
              city: 'Sinop',
              latitude: -11.81,
              longitude: -55.45,
              salesAmount: 250,
              salesCount: 2,
            ),
            AppBrazilStoreSalesPoint(
              id: 'sorriso',
              name: 'Loja Sorriso',
              uf: 'MT',
              municipalityCode: '5107925',
              city: 'Sorriso',
              latitude: -12.5425,
              longitude: -55.7211,
              salesAmount: 90,
              salesCount: 1,
            ),
          ],
          markerAggregation:
              AppBrazilStoreSalesMarkerAggregation.municipalities,
        );

        final sinop = groups.singleWhere(
          (group) => group.cityLabel == 'Sinop / MT',
        );
        final sorriso = groups.singleWhere(
          (group) => group.cityLabel == 'Sorriso / MT',
        );

        expect(sinop.isCluster, isTrue);
        expect(sinop.points.map((point) => point.id), <String>[
          'sinop-b',
          'sinop-a',
        ]);
        expect(sinop.salesAmount, 350);
        expect(sinop.salesCount, 3);
        expect(sinop.latitude, closeTo(-11.8352, 0.0001));
        expect(sorriso.isCluster, isFalse);
      },
    );

    test(
      'keeps municipalities with the same name separated by UF',
      () {
        final groups = AppBrazilStoreSalesMapData.buildMarkerGroups(
          const <AppBrazilStoreSalesPoint>[
            AppBrazilStoreSalesPoint(
              id: 'bom-jesus-pi',
              name: 'Loja Bom Jesus PI',
              uf: 'PI',
              city: 'Bom Jesus',
              latitude: -9.0745,
              longitude: -44.3586,
              salesAmount: 100,
              salesCount: 1,
            ),
            AppBrazilStoreSalesPoint(
              id: 'bom-jesus-rs',
              name: 'Loja Bom Jesus RS',
              uf: 'RS',
              city: 'Bom Jesus',
              latitude: -28.6695,
              longitude: -50.4301,
              salesAmount: 250,
              salesCount: 2,
            ),
          ],
          markerAggregation:
              AppBrazilStoreSalesMarkerAggregation.municipalities,
        );

        expect(groups, hasLength(2));
        expect(
          groups.map((group) => group.cityLabel).toSet(),
          <String>{'Bom Jesus / PI', 'Bom Jesus / RS'},
        );
        expect(groups.every((group) => group.isCluster), isFalse);
      },
    );

    test('reduces proximity clustering distance as zoom increases', () {
      expect(
        AppBrazilStoreSalesMapData.proximityClusterDistanceForZoom(
          baseDistanceDegrees: 0.6,
          zoomLevel: 1.5,
        ),
        closeTo(0.4, 0.001),
      );
      expect(
        AppBrazilStoreSalesMapData.proximityClusterDistanceForZoom(
          baseDistanceDegrees: 0.6,
          zoomLevel: 6,
        ),
        closeTo(0.1, 0.001),
      );
    });
  });

  group('Brazil GeoJSON asset', () {
    test('contains 27 UF features with UF property', () {
      final file = File(AppBrazilMapStaticData.brazilUfGeoJsonAssetPath);
      final payload =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final features = payload['features']! as List<Object?>;

      expect(features, hasLength(27));
      for (final feature in features.cast<Map<String, Object?>>()) {
        final properties = feature['properties']! as Map<String, Object?>;
        final uf = properties['UF'];

        expect(uf, isA<String>());
        expect(AppBrazilMapStaticData.ufCodes, contains(uf));
      }
    });
  });
}
