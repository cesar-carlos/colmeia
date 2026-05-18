import 'dart:convert';
import 'dart:io';

import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_snapshot.dart';
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

    test(
      'points content digest changes when visible branch metadata changes',
      () {
        const basePoint = AppBrazilStoreSalesPoint(
          id: 'store-1',
          name: 'Loja Base',
          fantasyName: 'Loja Base',
          branchName: 'Matriz',
          agentName: 'Agente 1',
          uf: 'MT',
          city: 'Cuiaba',
          municipalityCode: '5103403',
          latitude: -15.6,
          longitude: -56.1,
          salesAmount: 100,
          salesCount: 1,
          salesDataStatusLabel: 'Disponivel',
          locationResolution:
              AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
          subtitle: 'Empresa 1 - Filial 1',
        );

        final baseDigest = AppBrazilStoreSalesMapData.pointsContentDigest(
          const <AppBrazilStoreSalesPoint>[basePoint],
        );
        final renamedDigest = AppBrazilStoreSalesMapData.pointsContentDigest(
          const <AppBrazilStoreSalesPoint>[
            AppBrazilStoreSalesPoint(
              id: 'store-1',
              name: 'Loja Atualizada',
              fantasyName: 'Loja Atualizada',
              branchName: 'Matriz',
              agentName: 'Agente 1',
              uf: 'MT',
              city: 'Cuiaba',
              municipalityCode: '5103403',
              latitude: -15.6,
              longitude: -56.1,
              salesAmount: 100,
              salesCount: 1,
              salesDataStatusLabel: 'Disponivel',
              locationResolution:
                  AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
              subtitle: 'Empresa 1 - Filial 1',
            ),
          ],
        );
        final statusDigest = AppBrazilStoreSalesMapData.pointsContentDigest(
          const <AppBrazilStoreSalesPoint>[
            AppBrazilStoreSalesPoint(
              id: 'store-1',
              name: 'Loja Base',
              fantasyName: 'Loja Base',
              branchName: 'Matriz',
              agentName: 'Agente 1',
              uf: 'MT',
              city: 'Cuiaba',
              municipalityCode: '5103403',
              latitude: -15.6,
              longitude: -56.1,
              salesAmount: 100,
              salesCount: 1,
              salesDataStatusLabel: 'Indisponivel',
              locationResolution:
                  AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
              subtitle: 'Empresa 1 - Filial 1',
            ),
          ],
        );

        expect(renamedDigest, isNot(baseDigest));
        expect(statusDigest, isNot(baseDigest));
      },
    );

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
      'proximity clustering merges dense grids far below one group per store',
      () {
        const count = 400;
        final points = <AppBrazilStoreSalesPoint>[];
        for (var i = 0; i < count; i++) {
          points.add(
            AppBrazilStoreSalesPoint(
              id: 'store_$i',
              name: 'Store $i',
              uf: 'SP',
              latitude: -23.55 + (i % 20) * 0.001,
              longitude: -46.63 + (i ~/ 20) * 0.001,
              salesAmount: (count - i).toDouble(),
              salesCount: 1,
            ),
          );
        }

        final groups = AppBrazilStoreSalesMapData.buildMarkerGroups(
          points,
          enableProximityCluster: true,
          proximityClusterDistanceDegrees: 0.02,
        );

        expect(groups.length, lessThan(120));
        expect(groups.length, greaterThan(0));
      },
    );

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

    test('markerGroupContentFingerprint ignores point order in group', () {
      const p1 = AppBrazilStoreSalesPoint(
        id: 'z',
        name: 'Z',
        uf: 'MT',
        latitude: -12,
        longitude: -55,
        salesAmount: 10,
        salesCount: 1,
      );
      const p2 = AppBrazilStoreSalesPoint(
        id: 'a',
        name: 'A',
        uf: 'MT',
        latitude: -12.1,
        longitude: -55.1,
        salesAmount: 20,
        salesCount: 2,
      );
      final forward = AppBrazilStoreSalesMarkerGroup(
        points: <AppBrazilStoreSalesPoint>[p1, p2],
        latitude: -12.05,
        longitude: -55.05,
      );
      final reversed = AppBrazilStoreSalesMarkerGroup(
        points: <AppBrazilStoreSalesPoint>[p2, p1],
        latitude: -12.05,
        longitude: -55.05,
      );
      expect(
        AppBrazilStoreSalesMapData.markerGroupContentFingerprint(forward),
        AppBrazilStoreSalesMapData.markerGroupContentFingerprint(reversed),
      );
    });

    test(
      'snapshot builder resolves selected store, state and marker range',
      () {
        final snapshot = AppBrazilStoreSalesMapSnapshotBuilder.build(
          const AppBrazilStoreSalesMapSnapshotInput(
            points: <AppBrazilStoreSalesPoint>[
              AppBrazilStoreSalesPoint(
                id: 'sinop',
                name: 'Loja Sinop',
                uf: 'MT',
                city: 'Sinop',
                latitude: -11.8604,
                longitude: -55.5091,
                salesAmount: 100,
                salesCount: 2,
              ),
              AppBrazilStoreSalesPoint(
                id: 'paulista',
                name: 'Loja Paulista',
                uf: 'SP',
                city: 'Sao Paulo',
                latitude: -23.5505,
                longitude: -46.6333,
                salesAmount: 300,
                salesCount: 5,
              ),
            ],
            metric: AppBrazilStoreSalesMapMetric.revenue,
            selectedStoreId: 'paulista',
            requestedStateKey: 'MT',
            zoomLevel: 2,
            style: AppBrazilStoreSalesMapStyle.stateBubbles(height: 320),
          ),
          cachedReuseKey: 'reuse-key',
          defaultBranchName: 'Filial sem nome',
        );

        expect(snapshot.selectedPoint?.id, 'paulista');
        expect(snapshot.selectedStateKey, 'SP');
        expect(snapshot.selectedStateBucket?.uf, 'SP');
        expect(
          snapshot.stateBubbleBuckets.map((bucket) => bucket.uf),
          containsAll(<String>['MT', 'SP']),
        );
        expect(snapshot.minMarkerValue, 100);
        expect(snapshot.maxMarkerValue, 300);
        expect(snapshot.cachedReuseKey, 'reuse-key');
      },
    );

    test('snapshot reuse key is stable for equivalent point content', () {
      const pointsA = <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'sinop',
          name: 'Loja Sinop',
          uf: 'MT',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 100,
          salesCount: 2,
        ),
      ];
      const pointsB = <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'sinop',
          name: 'Loja Sinop',
          uf: 'MT',
          latitude: -11.8604,
          longitude: -55.5091,
          salesAmount: 100,
          salesCount: 2,
        ),
      ];

      final reuseKeyA = AppBrazilStoreSalesMapSnapshotBuilder.buildReuseKey(
        points: pointsA,
        fixedBranchIds: const <String>{'a'},
        filterBranchIds: const <String>{'b'},
        style: const AppBrazilStoreSalesMapStyle.standard(),
        metric: AppBrazilStoreSalesMapMetric.revenue,
        selectedStoreId: 'sinop',
        requestedStateKey: 'MT',
        activeRegionKey: null,
        zoomLevel: 2,
      );
      final reuseKeyB = AppBrazilStoreSalesMapSnapshotBuilder.buildReuseKey(
        points: pointsB,
        fixedBranchIds: const <String>{'a'},
        filterBranchIds: const <String>{'b'},
        style: const AppBrazilStoreSalesMapStyle.standard(),
        metric: AppBrazilStoreSalesMapMetric.revenue,
        selectedStoreId: 'sinop',
        requestedStateKey: 'MT',
        activeRegionKey: null,
        zoomLevel: 2,
      );

      expect(reuseKeyA, reuseKeyB);
    });

    test(
      'snapshot builder keeps requested state when selected store is missing',
      () {
        final snapshot = AppBrazilStoreSalesMapSnapshotBuilder.build(
          const AppBrazilStoreSalesMapSnapshotInput(
            points: <AppBrazilStoreSalesPoint>[
              AppBrazilStoreSalesPoint(
                id: 'sinop',
                name: 'Loja Sinop',
                uf: 'MT',
                latitude: -11.8604,
                longitude: -55.5091,
                salesAmount: 100,
                salesCount: 2,
              ),
            ],
            metric: AppBrazilStoreSalesMapMetric.revenue,
            selectedStoreId: 'missing',
            requestedStateKey: 'MT',
            zoomLevel: 2,
            style: AppBrazilStoreSalesMapStyle.standard(),
          ),
          cachedReuseKey: 'missing-selection',
          defaultBranchName: 'Filial sem nome',
        );

        expect(snapshot.selectedPoint, isNull);
        expect(snapshot.selectedMarkerGroup, isNull);
        expect(snapshot.selectedStateKey, 'MT');
        expect(snapshot.selectedStateBucket?.uf, 'MT');
      },
    );

    test('snapshot builder uses state bubbles without store markers', () {
      final snapshot = AppBrazilStoreSalesMapSnapshotBuilder.build(
        const AppBrazilStoreSalesMapSnapshotInput(
          points: <AppBrazilStoreSalesPoint>[
            AppBrazilStoreSalesPoint(
              id: 'sinop',
              name: 'Loja Sinop',
              uf: 'MT',
              latitude: -11.8604,
              longitude: -55.5091,
              salesAmount: 100,
              salesCount: 2,
            ),
            AppBrazilStoreSalesPoint(
              id: 'paulista',
              name: 'Loja Paulista',
              uf: 'SP',
              latitude: -23.5505,
              longitude: -46.6333,
              salesAmount: 300,
              salesCount: 5,
            ),
          ],
          metric: AppBrazilStoreSalesMapMetric.salesCount,
          zoomLevel: 2,
          style: AppBrazilStoreSalesMapStyle.stateBubbles(height: 320),
        ),
        cachedReuseKey: 'states-only',
        defaultBranchName: 'Filial sem nome',
      );

      expect(snapshot.markerGroups, isEmpty);
      expect(snapshot.stateBubbleBuckets, hasLength(2));
      expect(snapshot.minMarkerValue, 2);
      expect(snapshot.maxMarkerValue, 5);
    });

    test('snapshot builder changes proximity clustering with zoom level', () {
      const points = <AppBrazilStoreSalesPoint>[
        AppBrazilStoreSalesPoint(
          id: 'a',
          name: 'Loja A',
          uf: 'SP',
          latitude: -23.5505,
          longitude: -46.6333,
          salesAmount: 100,
          salesCount: 1,
        ),
        AppBrazilStoreSalesPoint(
          id: 'b',
          name: 'Loja B',
          uf: 'SP',
          latitude: -23.5614,
          longitude: -46.6559,
          salesAmount: 250,
          salesCount: 2,
        ),
      ];

      final wideZoomSnapshot = AppBrazilStoreSalesMapSnapshotBuilder.build(
        const AppBrazilStoreSalesMapSnapshotInput(
          points: points,
          metric: AppBrazilStoreSalesMapMetric.revenue,
          zoomLevel: 1.5,
          style: AppBrazilStoreSalesMapStyle(
            enableProximityCluster: true,
            proximityClusterDistanceDegrees: 0.05,
          ),
        ),
        cachedReuseKey: 'wide-zoom',
        defaultBranchName: 'Filial sem nome',
      );
      final closeZoomSnapshot = AppBrazilStoreSalesMapSnapshotBuilder.build(
        const AppBrazilStoreSalesMapSnapshotInput(
          points: points,
          metric: AppBrazilStoreSalesMapMetric.revenue,
          zoomLevel: 8,
          style: AppBrazilStoreSalesMapStyle(
            enableProximityCluster: true,
            proximityClusterDistanceDegrees: 0.05,
          ),
        ),
        cachedReuseKey: 'close-zoom',
        defaultBranchName: 'Filial sem nome',
      );

      expect(wideZoomSnapshot.markerGroups, hasLength(1));
      expect(closeZoomSnapshot.markerGroups, hasLength(2));
    });
  });

  group('Brazil GeoJSON asset', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    tearDown(AppBrazilMapStaticData.resetBrazilUfGeoJsonMemoryCacheForTests);

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

    test('precache materializes in-memory GeoJSON bytes', () async {
      expect(
        await AppBrazilMapStaticData.precacheBrazilUfGeoJsonAsset(),
        isTrue,
      );
      final bytes = AppBrazilMapStaticData.brazilUfGeoJsonBytesOrNull;
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(1000));
      expect(
        await AppBrazilMapStaticData.precacheBrazilUfGeoJsonAsset(),
        isFalse,
      );
      expect(
        identical(bytes, AppBrazilMapStaticData.brazilUfGeoJsonBytesOrNull),
        isTrue,
      );
    });
  });
}
