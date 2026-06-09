import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_points_content_digest.dart';

int salesLiveMapPointsContentDigest(Iterable<SalesLiveMapPoint> points) {
  final pointList = points is List<SalesLiveMapPoint>
      ? points
      : points.toList(growable: false);
  return brazilStoreSalesMapPointsContentDigest(
    pointList.map(_digestFieldsFromSalesLiveMapPoint),
  );
}

BrazilStoreSalesMapPointDigestFields _digestFieldsFromSalesLiveMapPoint(
  SalesLiveMapPoint point,
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
