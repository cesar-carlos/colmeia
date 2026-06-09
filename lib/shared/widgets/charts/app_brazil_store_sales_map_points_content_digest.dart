import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:flutter/foundation.dart';

const int brazilStoreSalesMapPointsContentDigestSeed = 0xBEE5CAFE;

@immutable
class BrazilStoreSalesMapPointDigestFields {
  const BrazilStoreSalesMapPointDigestFields({
    required this.id,
    required this.name,
    required this.salesAmount,
    required this.salesCount,
    required this.salesDataLoading,
    required this.salesDataUnavailable,
    required this.latitude,
    required this.longitude,
    required this.uf,
    this.fantasyName,
    this.branchName,
    this.companyCode,
    this.branchCode,
    this.agentName,
    this.salesDataStatusLabel,
    this.city,
    this.municipalityCode,
    this.locationResolutionName,
    this.subtitle,
  });

  factory BrazilStoreSalesMapPointDigestFields.fromChartPoint(
    AppBrazilStoreSalesPoint point,
  ) {
    return BrazilStoreSalesMapPointDigestFields(
      id: point.id,
      name: point.name,
      fantasyName: point.fantasyName,
      branchName: point.branchName,
      companyCode: point.companyCode,
      branchCode: point.branchCode,
      agentName: point.agentName,
      salesAmount: point.salesAmount,
      salesCount: point.salesCount,
      salesDataLoading: point.salesDataLoading,
      salesDataUnavailable: point.salesDataUnavailable,
      salesDataStatusLabel: point.salesDataStatusLabel,
      latitude: point.latitude,
      longitude: point.longitude,
      uf: point.uf,
      city: point.city,
      municipalityCode: point.municipalityCode,
      locationResolutionName: point.locationResolution?.name,
      subtitle: point.subtitle,
    );
  }

  final String id;
  final String name;
  final String? fantasyName;
  final String? branchName;
  final int? companyCode;
  final int? branchCode;
  final String? agentName;
  final double salesAmount;
  final int salesCount;
  final bool salesDataLoading;
  final bool salesDataUnavailable;
  final String? salesDataStatusLabel;
  final double latitude;
  final double longitude;
  final String uf;
  final String? city;
  final String? municipalityCode;
  final String? locationResolutionName;
  final String? subtitle;
}

int brazilStoreSalesMapPointsContentDigest(
  Iterable<BrazilStoreSalesMapPointDigestFields> points,
) {
  final pointList = points is List<BrazilStoreSalesMapPointDigestFields>
      ? points
      : points.toList(growable: false);
  var h = Object.hash(
    brazilStoreSalesMapPointsContentDigestSeed,
    pointList.length,
  );
  for (final point in pointList) {
    h = Object.hash(
      h,
      point.id,
      point.name,
      point.fantasyName ?? '',
      point.branchName ?? '',
      point.companyCode,
      point.branchCode,
      point.agentName ?? '',
      point.salesAmount,
      point.salesCount,
      point.salesDataLoading,
      point.salesDataUnavailable,
      point.salesDataStatusLabel ?? '',
      point.latitude,
      point.longitude,
      point.uf,
      point.city ?? '',
      point.municipalityCode ?? '',
      point.locationResolutionName,
      point.subtitle ?? '',
    );
  }
  return h;
}
