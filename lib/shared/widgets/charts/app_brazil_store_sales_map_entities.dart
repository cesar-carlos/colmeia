import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_enums.dart';

extension AppBrazilStoreSalesMapMetricX on AppBrazilStoreSalesMapMetric {
  String get key => switch (this) {
    AppBrazilStoreSalesMapMetric.revenue => 'revenue',
    AppBrazilStoreSalesMapMetric.salesCount => 'salesCount',
  };

  num valueForPoint(AppBrazilStoreSalesPoint point) => switch (this) {
    AppBrazilStoreSalesMapMetric.revenue => point.salesAmount,
    AppBrazilStoreSalesMapMetric.salesCount => point.salesCount,
  };

  num valueForBucket(AppBrazilStoreSalesStateBucket bucket) => switch (this) {
    AppBrazilStoreSalesMapMetric.revenue => bucket.salesAmount,
    AppBrazilStoreSalesMapMetric.salesCount => bucket.salesCount,
  };
}

class AppBrazilStoreSalesPoint {
  const AppBrazilStoreSalesPoint({
    required this.id,
    required this.name,
    required this.uf,
    required this.latitude,
    required this.longitude,
    required this.salesAmount,
    required this.salesCount,
    this.municipalityCode,
    this.city,
    this.fantasyName,
    this.branchName,
    this.companyCode,
    this.branchCode,
    this.agentName,
    this.salesDataLoading = false,
    this.salesDataUnavailable = false,
    this.salesDataStatusLabel,
    this.locationResolution,
    this.subtitle,
    this.payload,
  });

  final String id;
  final String name;
  final String uf;
  final double latitude;
  final double longitude;
  final double salesAmount;
  final int salesCount;
  final String? municipalityCode;
  final String? city;
  final String? fantasyName;
  final String? branchName;
  final int? companyCode;
  final int? branchCode;
  final String? agentName;
  final bool salesDataLoading;
  final bool salesDataUnavailable;
  final String? salesDataStatusLabel;
  final AppBrazilStoreSalesLocationResolution? locationResolution;
  final String? subtitle;
  final Object? payload;
}

class AppBrazilStoreSalesStateBucket {
  const AppBrazilStoreSalesStateBucket({
    required this.uf,
    required this.stateName,
    required this.regionKey,
    required this.regionName,
    required this.salesAmount,
    required this.salesCount,
    required this.storeCount,
  });

  final String uf;
  final String stateName;
  final String regionKey;
  final String regionName;
  final double salesAmount;
  final int salesCount;
  final int storeCount;
}
