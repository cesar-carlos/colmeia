import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_region_map_shape_source_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mapDefinition = AppMapDefinition.memory(
    sourceBytes: _geoJsonBytes,
    shapeDataField: 'UF',
    regionLevel: AppMapRegionLevel.state,
  );
  const regionKeys = <String>['SP'];
  const regionLabels = <String>['São Paulo'];
  const itemCount = 1;

  group('resolveMetricRange', () {
    test('returns safe defaults when values are empty', () {
      final result = resolveMetricRange(const <double>[]);

      expect(result.minValue, 0);
      expect(result.maxValue, 0);
      expect(result.range, 1);
    });

    test('returns unit range when all values are equal', () {
      final result = resolveMetricRange(const <double>[42, 42, 42]);

      expect(result.minValue, 42);
      expect(result.maxValue, 42);
      expect(result.range, 1);
    });

    test('returns min max and span for distinct values', () {
      final result = resolveMetricRange(const <double>[10, 30, 20]);

      expect(result.minValue, 10);
      expect(result.maxValue, 30);
      expect(result.range, 20);
    });
  });

  group('SyncfusionRegionMapShapeSourceCache', () {
    test('geometryFingerprint is stable for identical inputs', () {
      final cache = SyncfusionRegionMapShapeSourceCache();

      final first = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: true,
      );
      final second = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: true,
      );

      expect(second, first);
    });

    test('geometryFingerprint changes when geometry inputs change', () {
      final cache = SyncfusionRegionMapShapeSourceCache();
      final baseline = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );
      final moreItems = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount + 1,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );
      final withLabels = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: true,
      );

      expect(moreItems, isNot(equals(baseline)));
      expect(withLabels, isNot(equals(baseline)));
    });

    test('resolve returns cached shape source for same fingerprint', () {
      final cache = SyncfusionRegionMapShapeSourceCache();
      final fingerprint = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );

      final first = cache.resolve(
        geometryFingerprint: fingerprint,
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );
      final second = cache.resolve(
        geometryFingerprint: fingerprint,
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );

      expect(identical(first, second), isTrue);
    });

    test('invalidate forces shape source rebuild on next resolve', () {
      final cache = SyncfusionRegionMapShapeSourceCache();
      final fingerprint = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );

      final beforeInvalidate = cache.resolve(
        geometryFingerprint: fingerprint,
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );
      cache.invalidate();
      final afterInvalidate = cache.resolve(
        geometryFingerprint: fingerprint,
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );

      expect(identical(beforeInvalidate, afterInvalidate), isFalse);
    });

    test('updateMetricBuffer does not invalidate cached geometry', () {
      final cache = SyncfusionRegionMapShapeSourceCache();
      final fingerprint = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );

      final beforeMetrics = cache.resolve(
        geometryFingerprint: fingerprint,
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );
      cache.updateMetricBuffer(
        metricValues: const <double>[100],
        lowColor: Colors.blue,
        highColor: Colors.red,
        metricMinValue: 0,
        metricRange: 100,
      );
      final afterMetrics = cache.resolve(
        geometryFingerprint: fingerprint,
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );

      expect(identical(beforeMetrics, afterMetrics), isTrue);
    });

    test('dispose clears cached shape source', () {
      final cache = SyncfusionRegionMapShapeSourceCache();
      final fingerprint = cache.geometryFingerprint(
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );

      final beforeDispose = cache.resolve(
        geometryFingerprint: fingerprint,
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );
      cache.dispose();
      final afterDispose = cache.resolve(
        geometryFingerprint: fingerprint,
        mapDefinition: mapDefinition,
        itemCount: itemCount,
        regionKeys: regionKeys,
        regionLabels: regionLabels,
        showDataLabels: false,
      );

      expect(identical(beforeDispose, afterDispose), isFalse);
    });
  });
}

final Uint8List _geoJsonBytes = Uint8List.fromList(
  utf8.encode(
    jsonEncode(<String, Object?>{
      'type': 'FeatureCollection',
      'features': <Object?>[
        <String, Object?>{
          'type': 'Feature',
          'properties': <String, String>{'UF': 'SP'},
          'geometry': <String, Object?>{
            'type': 'Polygon',
            'coordinates': <Object?>[
              <Object?>[
                <double>[-48, -24],
                <double>[-46, -24],
                <double>[-46, -22],
                <double>[-48, -22],
                <double>[-48, -24],
              ],
            ],
          },
        },
      ],
    }),
  ),
);
