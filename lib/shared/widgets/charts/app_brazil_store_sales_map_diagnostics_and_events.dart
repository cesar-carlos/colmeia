import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_entities.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_enums.dart';
import 'package:flutter/material.dart';

@immutable
class AppBrazilStoreSalesMapDiagnostics {
  const AppBrazilStoreSalesMapDiagnostics({
    required this.totalPointCount,
    required this.validPointCount,
    required this.invalidCoordinateCount,
    required this.unknownUfCount,
    required this.filteredByRegionCount,
    this.resolvedByProvidedGeoPointCount = 0,
    this.resolvedByIbgeMunicipalityCodeCount = 0,
    this.resolvedByCepCount = 0,
    this.resolvedByCityUfCount = 0,
    this.resolvedByCapitalUfCount = 0,
    this.resolvedByStateUfCount = 0,
    this.unknownResolutionCount = 0,
  });

  final int totalPointCount;
  final int validPointCount;
  final int invalidCoordinateCount;
  final int unknownUfCount;
  final int filteredByRegionCount;
  final int resolvedByProvidedGeoPointCount;
  final int resolvedByIbgeMunicipalityCodeCount;
  final int resolvedByCepCount;
  final int resolvedByCityUfCount;
  final int resolvedByCapitalUfCount;
  final int resolvedByStateUfCount;
  final int unknownResolutionCount;

  int get discardedPointCount =>
      invalidCoordinateCount + unknownUfCount + filteredByRegionCount;

  bool get hasDiscardedPoints => discardedPointCount > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppBrazilStoreSalesMapDiagnostics &&
        totalPointCount == other.totalPointCount &&
        validPointCount == other.validPointCount &&
        invalidCoordinateCount == other.invalidCoordinateCount &&
        unknownUfCount == other.unknownUfCount &&
        filteredByRegionCount == other.filteredByRegionCount &&
        resolvedByProvidedGeoPointCount ==
            other.resolvedByProvidedGeoPointCount &&
        resolvedByIbgeMunicipalityCodeCount ==
            other.resolvedByIbgeMunicipalityCodeCount &&
        resolvedByCepCount == other.resolvedByCepCount &&
        resolvedByCityUfCount == other.resolvedByCityUfCount &&
        resolvedByCapitalUfCount == other.resolvedByCapitalUfCount &&
        resolvedByStateUfCount == other.resolvedByStateUfCount &&
        unknownResolutionCount == other.unknownResolutionCount;
  }

  @override
  int get hashCode => Object.hash(
    totalPointCount,
    validPointCount,
    invalidCoordinateCount,
    unknownUfCount,
    filteredByRegionCount,
    resolvedByProvidedGeoPointCount,
    resolvedByIbgeMunicipalityCodeCount,
    resolvedByCepCount,
    resolvedByCityUfCount,
    resolvedByCapitalUfCount,
    resolvedByStateUfCount,
    unknownResolutionCount,
  );
}

class AppBrazilStoreSalesStateBubble {
  const AppBrazilStoreSalesStateBubble({
    required this.bucket,
  });

  final AppBrazilStoreSalesStateBucket bucket;
}

class AppBrazilStoreSalesPointTapEvent {
  const AppBrazilStoreSalesPointTapEvent({
    required this.point,
    required this.index,
    required this.metric,
  });

  final AppBrazilStoreSalesPoint point;
  final int index;
  final AppBrazilStoreSalesMapMetric metric;
}

class AppBrazilStoreSalesPointClusterTapEvent {
  const AppBrazilStoreSalesPointClusterTapEvent({
    required this.points,
    required this.index,
    required this.metric,
    required this.latitude,
    required this.longitude,
    required this.salesAmount,
    required this.salesCount,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final int index;
  final AppBrazilStoreSalesMapMetric metric;
  final double latitude;
  final double longitude;
  final double salesAmount;
  final int salesCount;
}

class AppBrazilStoreSalesMunicipalityTapEvent {
  const AppBrazilStoreSalesMunicipalityTapEvent({
    required this.points,
    required this.index,
    required this.metric,
    required this.latitude,
    required this.longitude,
    required this.salesAmount,
    required this.salesCount,
  });

  final List<AppBrazilStoreSalesPoint> points;
  final int index;
  final AppBrazilStoreSalesMapMetric metric;
  final double latitude;
  final double longitude;
  final double salesAmount;
  final int salesCount;

  String get uf => points.isEmpty ? '' : points.first.uf.trim().toUpperCase();

  String get city {
    if (points.isEmpty) {
      return '';
    }
    return points.first.city?.trim() ?? '';
  }

  int get branchCount => points.length;
}
