import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

/// Caches [MapShapeSource] by geometry fingerprint while metric colors follow
/// the latest values through a live buffer (avoids GeoJSON re-parse on toggles).
class SyncfusionRegionMapShapeSourceCache {
  MapShapeSource? _cachedMapShapeSource;
  int? _cachedGeometryShapeFingerprint;

  final List<double> _liveShapeMetricValues = <double>[];
  Color _liveShapeLowColor = Colors.transparent;
  Color _liveShapeHighColor = Colors.transparent;
  double _liveShapeMetricMinValue = 0;
  double _liveShapeMetricRange = 1;

  void dispose() {
    _cachedMapShapeSource = null;
    _cachedGeometryShapeFingerprint = null;
  }

  void invalidate() {
    _cachedMapShapeSource = null;
    _cachedGeometryShapeFingerprint = null;
  }

  void updateMetricBuffer({
    required List<double> metricValues,
    required Color lowColor,
    required Color highColor,
    required double metricMinValue,
    required double metricRange,
  }) {
    _liveShapeLowColor = lowColor;
    _liveShapeHighColor = highColor;
    _liveShapeMetricValues
      ..clear()
      ..addAll(metricValues);
    _liveShapeMetricMinValue = metricMinValue;
    _liveShapeMetricRange = metricRange;
  }

  int geometryFingerprint({
    required AppMapDefinition mapDefinition,
    required int itemCount,
    required List<String> regionKeys,
    required List<String> regionLabels,
    required bool showDataLabels,
  }) {
    final def = mapDefinition;
    final bytes = def.bytes;
    final int bytesTag;
    if (bytes == null || bytes.isEmpty) {
      bytesTag = 0;
    } else {
      final mid = bytes.length ~/ 2;
      bytesTag = Object.hash(
        bytes.length,
        bytes[0] ^ bytes[mid] ^ bytes[bytes.length - 1],
      );
    }

    return Object.hash(
      def.sourceType,
      def.pathOrUrl,
      bytesTag,
      def.shapeDataField,
      def.regionLevel,
      itemCount,
      Object.hashAll(regionKeys),
      showDataLabels ? Object.hashAll(regionLabels) : 0,
    );
  }

  MapShapeSource resolve({
    required int geometryFingerprint,
    required AppMapDefinition mapDefinition,
    required int itemCount,
    required List<String> regionKeys,
    required List<String> regionLabels,
    required bool showDataLabels,
  }) {
    if (_cachedGeometryShapeFingerprint == geometryFingerprint &&
        _cachedMapShapeSource != null) {
      return _cachedMapShapeSource!;
    }

    final shapeSource = _buildShapeSource(
      mapDefinition: mapDefinition,
      itemCount: itemCount,
      regionKeys: regionKeys,
      regionLabels: regionLabels,
      showDataLabels: showDataLabels,
    );
    _cachedMapShapeSource = shapeSource;
    _cachedGeometryShapeFingerprint = geometryFingerprint;
    return shapeSource;
  }

  Color _shapeColorValueForIndex(int index) {
    final values = _liveShapeMetricValues;
    if (values.isEmpty || index < 0 || index >= values.length) {
      return _liveShapeLowColor;
    }
    final normalized =
        ((values[index] - _liveShapeMetricMinValue) / _liveShapeMetricRange)
            .clamp(
              0.0,
              1.0,
            );
    return Color.lerp(_liveShapeLowColor, _liveShapeHighColor, normalized)!;
  }

  MapShapeSource _buildShapeSource({
    required AppMapDefinition mapDefinition,
    required int itemCount,
    required List<String> regionKeys,
    required List<String> regionLabels,
    required bool showDataLabels,
  }) {
    final shapeDataField = mapDefinition.shapeDataField;
    final def = mapDefinition;
    return switch (def.sourceType) {
      AppMapSourceType.asset => MapShapeSource.asset(
        def.pathOrUrl!,
        shapeDataField: shapeDataField,
        dataCount: itemCount,
        primaryValueMapper: regionKeys.elementAt,
        dataLabelMapper: showDataLabels ? regionLabels.elementAt : null,
        shapeColorValueMapper: _shapeColorValueForIndex,
      ),
      AppMapSourceType.network => MapShapeSource.network(
        mapDefinition.pathOrUrl!,
        shapeDataField: shapeDataField,
        dataCount: itemCount,
        primaryValueMapper: regionKeys.elementAt,
        dataLabelMapper: showDataLabels ? regionLabels.elementAt : null,
        shapeColorValueMapper: _shapeColorValueForIndex,
      ),
      AppMapSourceType.memory => MapShapeSource.memory(
        mapDefinition.bytes!,
        shapeDataField: shapeDataField,
        dataCount: itemCount,
        primaryValueMapper: regionKeys.elementAt,
        dataLabelMapper: showDataLabels ? regionLabels.elementAt : null,
        shapeColorValueMapper: _shapeColorValueForIndex,
      ),
    };
  }
}

({double minValue, double maxValue, double range}) resolveMetricRange(
  List<double> values,
) {
  if (values.isEmpty) {
    return (minValue: 0, maxValue: 0, range: 1);
  }

  var minValue = values.first;
  var maxValue = values.first;
  for (final value in values.skip(1)) {
    if (value < minValue) {
      minValue = value;
    }
    if (value > maxValue) {
      maxValue = value;
    }
  }

  final rawRange = maxValue - minValue;
  return (
    minValue: minValue,
    maxValue: maxValue,
    range: rawRange.abs() < 0.0001 ? 1.0 : rawRange,
  );
}
