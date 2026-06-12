part of 'app_brazil_store_sales_map_data.dart';

class AppBrazilStoreSalesMapPreparedData {
  const AppBrazilStoreSalesMapPreparedData({
    required this.validPoints,
    required this.buckets,
    required this.diagnostics,
  });

  final List<AppBrazilStoreSalesPoint> validPoints;
  final List<AppBrazilStoreSalesStateBucket> buckets;
  final AppBrazilStoreSalesMapDiagnostics diagnostics;
}

class AppBrazilStoreSalesMarkerGroup {
  const AppBrazilStoreSalesMarkerGroup({
    required this.points,
    this.aggregation = AppBrazilStoreSalesMarkerAggregation.stores,
    double? latitude,
    double? longitude,
  }) : _latitude = latitude,
       _longitude = longitude,
       assert(points.length > 0, 'points must not be empty');

  final List<AppBrazilStoreSalesPoint> points;
  final AppBrazilStoreSalesMarkerAggregation aggregation;
  final double? _latitude;
  final double? _longitude;

  AppBrazilStoreSalesPoint get primaryPoint => points.first;

  bool get isCluster => points.length > 1;

  bool get isMunicipalityAggregate =>
      aggregation == AppBrazilStoreSalesMarkerAggregation.municipalities;

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
      regionName: regionKey,
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
  _MutableMarkerGroup(
    AppBrazilStoreSalesPoint point, {
    this.aggregation = AppBrazilStoreSalesMarkerAggregation.stores,
  }) : uf = AppBrazilStoreSalesMapData.normalizeUf(point.uf),
       latitude = point.latitude,
       longitude = point.longitude,
       _latitudeTotal = point.latitude,
       _longitudeTotal = point.longitude,
       _count = 1,
       _points = <AppBrazilStoreSalesPoint>[point];

  factory _MutableMarkerGroup.fromPoints(
    List<AppBrazilStoreSalesPoint> points, {
    AppBrazilStoreSalesMarkerAggregation aggregation =
        AppBrazilStoreSalesMarkerAggregation.stores,
  }) {
    final group = _MutableMarkerGroup(points.first, aggregation: aggregation);
    points.skip(1).forEach(group.add);
    return group;
  }

  final String uf;
  final AppBrazilStoreSalesMarkerAggregation aggregation;
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
      aggregation: aggregation,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
