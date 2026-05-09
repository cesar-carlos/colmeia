import 'dart:math' as math;

import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

abstract final class AppBrazilStoreSalesMapData {
  static String normalizeUf(String uf) {
    return uf.trim().toUpperCase();
  }

  static bool isKnownUf(String uf) {
    return AppBrazilMapStaticData.stateNamesByUf.containsKey(normalizeUf(uf));
  }

  static bool hasValidCoordinates(AppBrazilStoreSalesPoint point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  static bool pointMatchesRegion(
    AppBrazilStoreSalesPoint point,
    String? regionKey,
  ) {
    if (regionKey == null) {
      return true;
    }

    return AppBrazilMapStaticData.regionKeyForUf(point.uf) == regionKey;
  }

  static List<AppBrazilStoreSalesPoint> validMapPoints(
    Iterable<AppBrazilStoreSalesPoint> points, {
    String? regionKey,
  }) {
    return points
        .where(
          (point) =>
              isKnownUf(point.uf) &&
              hasValidCoordinates(point) &&
              pointMatchesRegion(point, regionKey),
        )
        .toList(growable: false);
  }

  static AppBrazilStoreSalesMapDiagnostics buildDiagnostics(
    Iterable<AppBrazilStoreSalesPoint> points, {
    String? regionKey,
  }) {
    var totalPointCount = 0;
    var validPointCount = 0;
    var invalidCoordinateCount = 0;
    var unknownUfCount = 0;
    var filteredByRegionCount = 0;

    for (final point in points) {
      totalPointCount += 1;
      if (!isKnownUf(point.uf)) {
        unknownUfCount += 1;
        continue;
      }

      if (!hasValidCoordinates(point)) {
        invalidCoordinateCount += 1;
        continue;
      }

      if (!pointMatchesRegion(point, regionKey)) {
        filteredByRegionCount += 1;
        continue;
      }

      validPointCount += 1;
    }

    return AppBrazilStoreSalesMapDiagnostics(
      totalPointCount: totalPointCount,
      validPointCount: validPointCount,
      invalidCoordinateCount: invalidCoordinateCount,
      unknownUfCount: unknownUfCount,
      filteredByRegionCount: filteredByRegionCount,
    );
  }

  static List<AppBrazilStoreSalesPoint> filterPointsByRegion(
    Iterable<AppBrazilStoreSalesPoint> points,
    String? regionKey,
  ) {
    if (regionKey == null) {
      return points
          .where((point) => isKnownUf(point.uf))
          .toList(
            growable: false,
          );
    }

    return points
        .where(
          (point) =>
              isKnownUf(point.uf) && pointMatchesRegion(point, regionKey),
        )
        .toList(growable: false);
  }

  static List<AppBrazilStoreSalesStateBucket> buildStateBuckets(
    Iterable<AppBrazilStoreSalesPoint> points, {
    bool includeEmptyStates = true,
    String? regionKey,
  }) {
    final buckets = <String, _MutableStateBucket>{};
    final includedUfs = _includedUfCodes(regionKey);

    if (includeEmptyStates) {
      for (final uf in includedUfs) {
        buckets[uf] = _MutableStateBucket.fromUf(uf);
      }
    }

    for (final point in points) {
      final uf = normalizeUf(point.uf);
      if (!includedUfs.contains(uf)) {
        continue;
      }

      buckets.putIfAbsent(
          uf,
          () => _MutableStateBucket.fromUf(uf),
        )
        ..salesAmount += point.salesAmount
        ..salesCount += point.salesCount
        ..storeCount += 1;
    }

    return [
      for (final uf in includedUfs)
        if (buckets.containsKey(uf)) buckets[uf]!.toImmutable(),
    ];
  }

  static List<AppBrazilStoreSalesMarkerGroup> buildMarkerGroups(
    Iterable<AppBrazilStoreSalesPoint> points, {
    bool collapseSameCoordinateMarkers = true,
    bool enableProximityCluster = false,
    double proximityClusterDistanceDegrees = 0.45,
    int coordinatePrecision = 4,
    AppBrazilStoreSalesMarkerAggregation markerAggregation =
        AppBrazilStoreSalesMarkerAggregation.stores,
    String? regionKey,
  }) {
    final validPoints = validMapPoints(points, regionKey: regionKey);
    if (markerAggregation ==
        AppBrazilStoreSalesMarkerAggregation.municipalities) {
      return _buildMunicipalityMarkerGroups(
        validPoints,
        coordinatePrecision,
      );
    }

    if (enableProximityCluster && proximityClusterDistanceDegrees > 0) {
      return _buildProximityMarkerGroups(
        validPoints,
        proximityClusterDistanceDegrees,
      );
    }

    if (!collapseSameCoordinateMarkers) {
      return [
        for (final point in validPoints)
          AppBrazilStoreSalesMarkerGroup(points: [point]),
      ];
    }

    final groups = <String, List<AppBrazilStoreSalesPoint>>{};
    for (final point in validPoints) {
      final key = _coordinateKey(point, coordinatePrecision);
      groups.putIfAbsent(key, () => <AppBrazilStoreSalesPoint>[]).add(point);
    }

    return [
      for (final points in groups.values)
        AppBrazilStoreSalesMarkerGroup(
          points: [...points]
            ..sort(
              (left, right) => right.salesAmount.compareTo(left.salesAmount),
            ),
        ),
    ];
  }

  static double markerSizeFor({
    required num value,
    required num minValue,
    required num maxValue,
    required double minSize,
    required double maxSize,
  }) {
    final safeMinSize = math.min(minSize, maxSize);
    final safeMaxSize = math.max(minSize, maxSize);
    if (!value.isFinite || !minValue.isFinite || !maxValue.isFinite) {
      return safeMinSize;
    }

    if (safeMaxSize == safeMinSize) {
      return safeMinSize;
    }

    if (maxValue <= minValue) {
      return safeMinSize + ((safeMaxSize - safeMinSize) / 2);
    }

    final ratio = ((value - minValue) / (maxValue - minValue)).clamp(0, 1);
    return safeMinSize + ((safeMaxSize - safeMinSize) * ratio.toDouble());
  }

  static double proximityClusterDistanceForZoom({
    required double baseDistanceDegrees,
    required double zoomLevel,
  }) {
    if (!baseDistanceDegrees.isFinite || baseDistanceDegrees <= 0) {
      return 0;
    }

    final safeZoomLevel = zoomLevel.isFinite && zoomLevel > 0 ? zoomLevel : 1.0;
    return baseDistanceDegrees / safeZoomLevel;
  }

  static List<String> _includedUfCodes(String? regionKey) {
    if (regionKey == null) {
      return AppBrazilMapStaticData.ufCodes;
    }

    return [
      for (final uf in AppBrazilMapStaticData.ufCodes)
        if (AppBrazilMapStaticData.regionKeyForUf(uf) == regionKey) uf,
    ];
  }

  static String _coordinateKey(
    AppBrazilStoreSalesPoint point,
    int coordinatePrecision,
  ) {
    final safePrecision = coordinatePrecision.clamp(0, 8);
    return [
      point.latitude.toStringAsFixed(safePrecision),
      point.longitude.toStringAsFixed(safePrecision),
      normalizeUf(point.uf),
    ].join(':');
  }

  static String _municipalityKey(
    AppBrazilStoreSalesPoint point,
    int coordinatePrecision,
  ) {
    final municipalityCode = point.municipalityCode?.trim();
    if (municipalityCode != null && municipalityCode.isNotEmpty) {
      return 'ibge:${municipalityCode.toUpperCase()}';
    }

    final city = point.city?.trim();
    if (city != null && city.isNotEmpty) {
      return 'city:${city.toUpperCase()}:${normalizeUf(point.uf)}';
    }

    return 'coordinate:${_coordinateKey(point, coordinatePrecision)}';
  }

  static List<AppBrazilStoreSalesMarkerGroup> _buildMunicipalityMarkerGroups(
    List<AppBrazilStoreSalesPoint> validPoints,
    int coordinatePrecision,
  ) {
    final groups = <String, List<AppBrazilStoreSalesPoint>>{};
    for (final point in validPoints) {
      final key = _municipalityKey(point, coordinatePrecision);
      groups.putIfAbsent(key, () => <AppBrazilStoreSalesPoint>[]).add(point);
    }

    return [
      for (final points in groups.values)
        _MutableMarkerGroup.fromPoints(points).toImmutable(),
    ];
  }

  static List<AppBrazilStoreSalesMarkerGroup> _buildProximityMarkerGroups(
    List<AppBrazilStoreSalesPoint> validPoints,
    double distanceDegrees,
  ) {
    final groups = <_MutableMarkerGroup>[];
    final sortedPoints = [...validPoints]
      ..sort((left, right) => right.salesAmount.compareTo(left.salesAmount));

    for (final point in sortedPoints) {
      _MutableMarkerGroup? closestGroup;
      var closestDistance = double.infinity;

      for (final group in groups) {
        if (group.uf != normalizeUf(point.uf)) {
          continue;
        }

        final distance = _distanceDegrees(
          latitudeA: group.latitude,
          longitudeA: group.longitude,
          latitudeB: point.latitude,
          longitudeB: point.longitude,
        );
        if (distance <= distanceDegrees && distance < closestDistance) {
          closestGroup = group;
          closestDistance = distance;
        }
      }

      if (closestGroup == null) {
        groups.add(_MutableMarkerGroup(point));
      } else {
        closestGroup.add(point);
      }
    }

    return [
      for (final group in groups) group.toImmutable(),
    ];
  }

  static double _distanceDegrees({
    required double latitudeA,
    required double longitudeA,
    required double latitudeB,
    required double longitudeB,
  }) {
    final latitudeDistance = latitudeA - latitudeB;
    final longitudeDistance = longitudeA - longitudeB;
    return math.sqrt(
      (latitudeDistance * latitudeDistance) +
          (longitudeDistance * longitudeDistance),
    );
  }
}

class AppBrazilStoreSalesMarkerGroup {
  const AppBrazilStoreSalesMarkerGroup({
    required this.points,
    double? latitude,
    double? longitude,
  }) : _latitude = latitude,
       _longitude = longitude,
       assert(points.length > 0, 'points must not be empty');

  final List<AppBrazilStoreSalesPoint> points;
  final double? _latitude;
  final double? _longitude;

  AppBrazilStoreSalesPoint get primaryPoint => points.first;

  bool get isCluster => points.length > 1;

  double get latitude => _latitude ?? primaryPoint.latitude;

  double get longitude => _longitude ?? primaryPoint.longitude;

  String get uf => AppBrazilStoreSalesMapData.normalizeUf(primaryPoint.uf);

  String get cityLabel {
    final city = primaryPoint.city?.trim();
    if (city != null && city.isNotEmpty) {
      return '$city / $uf';
    }

    return uf;
  }

  double get salesAmount {
    return points.fold<double>(
      0,
      (total, point) => total + point.salesAmount,
    );
  }

  int get salesCount {
    return points.fold<int>(
      0,
      (total, point) => total + point.salesCount,
    );
  }

  num valueForMetric(AppBrazilStoreSalesMapMetric metric) {
    return switch (metric) {
      AppBrazilStoreSalesMapMetric.revenue => salesAmount,
      AppBrazilStoreSalesMapMetric.salesCount => salesCount,
    };
  }
}

class _MutableStateBucket {
  _MutableStateBucket({
    required this.uf,
    required this.stateName,
    required this.regionKey,
    required this.regionName,
  });

  factory _MutableStateBucket.fromUf(String uf) {
    final regionKey = AppBrazilMapStaticData.regionKeyForUf(uf) ?? '';
    return _MutableStateBucket(
      uf: uf,
      stateName: AppBrazilMapStaticData.stateNameForUf(uf),
      regionKey: regionKey,
      regionName: AppBrazilMapStaticData.regionNamesByKey[regionKey] ?? '',
    );
  }

  final String uf;
  final String stateName;
  final String regionKey;
  final String regionName;
  double salesAmount = 0;
  int salesCount = 0;
  int storeCount = 0;

  AppBrazilStoreSalesStateBucket toImmutable() {
    return AppBrazilStoreSalesStateBucket(
      uf: uf,
      stateName: stateName,
      regionKey: regionKey,
      regionName: regionName,
      salesAmount: salesAmount,
      salesCount: salesCount,
      storeCount: storeCount,
    );
  }
}

class _MutableMarkerGroup {
  _MutableMarkerGroup(AppBrazilStoreSalesPoint point)
    : uf = AppBrazilStoreSalesMapData.normalizeUf(point.uf),
      latitude = point.latitude,
      longitude = point.longitude,
      _latitudeTotal = point.latitude,
      _longitudeTotal = point.longitude,
      _count = 1,
      _points = <AppBrazilStoreSalesPoint>[point];

  factory _MutableMarkerGroup.fromPoints(
    List<AppBrazilStoreSalesPoint> points,
  ) {
    final group = _MutableMarkerGroup(points.first);
    points.skip(1).forEach(group.add);
    return group;
  }

  final String uf;
  final List<AppBrazilStoreSalesPoint> _points;
  double latitude;
  double longitude;
  double _latitudeTotal;
  double _longitudeTotal;
  int _count;

  void add(AppBrazilStoreSalesPoint point) {
    _points.add(point);
    _latitudeTotal += point.latitude;
    _longitudeTotal += point.longitude;
    _count += 1;
    latitude = _latitudeTotal / _count;
    longitude = _longitudeTotal / _count;
  }

  AppBrazilStoreSalesMarkerGroup toImmutable() {
    return AppBrazilStoreSalesMarkerGroup(
      points: [..._points]
        ..sort(
          (left, right) => right.salesAmount.compareTo(left.salesAmount),
        ),
      latitude: latitude,
      longitude: longitude,
    );
  }
}
