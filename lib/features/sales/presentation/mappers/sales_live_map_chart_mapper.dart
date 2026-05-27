import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

const int _kSalesLiveMapPointsDigestSeed = 0xBEE5CAFE;

abstract final class SalesLiveMapChartMapper {
  static AppBrazilStoreSalesMapMetric toChartMetric(
    SalesLiveMapMetric metric,
  ) {
    return switch (metric) {
      SalesLiveMapMetric.revenue => AppBrazilStoreSalesMapMetric.revenue,
      SalesLiveMapMetric.salesCount => AppBrazilStoreSalesMapMetric.salesCount,
    };
  }

  static SalesLiveMapMetric fromChartMetric(
    AppBrazilStoreSalesMapMetric metric,
  ) {
    return switch (metric) {
      AppBrazilStoreSalesMapMetric.revenue => SalesLiveMapMetric.revenue,
      AppBrazilStoreSalesMapMetric.salesCount => SalesLiveMapMetric.salesCount,
    };
  }

  static AppBrazilStoreSalesPoint toChartPoint(SalesLiveMapPoint point) {
    return AppBrazilStoreSalesPoint(
      id: point.id,
      name: point.name,
      uf: point.uf,
      latitude: point.latitude,
      longitude: point.longitude,
      salesAmount: point.salesAmount,
      salesCount: point.salesCount,
      municipalityCode: point.municipalityCode,
      city: point.city,
      fantasyName: point.fantasyName,
      branchName: point.branchName,
      companyCode: point.companyCode,
      branchCode: point.branchCode,
      agentName: point.agentName,
      salesDataLoading: point.salesDataLoading,
      salesDataUnavailable: point.salesDataUnavailable,
      salesDataStatusLabel: point.salesDataStatusLabel,
      locationResolution: switch (point.locationResolution) {
        SalesLiveMapLocationResolution.providedGeoPoint =>
          AppBrazilStoreSalesLocationResolution.providedGeoPoint,
        SalesLiveMapLocationResolution.ibgeMunicipalityCode =>
          AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
        SalesLiveMapLocationResolution.cep =>
          AppBrazilStoreSalesLocationResolution.cep,
        SalesLiveMapLocationResolution.cityUf =>
          AppBrazilStoreSalesLocationResolution.cityUf,
        SalesLiveMapLocationResolution.capitalUf =>
          AppBrazilStoreSalesLocationResolution.capitalUf,
        SalesLiveMapLocationResolution.stateUf =>
          AppBrazilStoreSalesLocationResolution.stateUf,
        null => null,
      },
      subtitle: point.subtitle,
      payload: point.payload,
    );
  }

  static List<AppBrazilStoreSalesPoint> toChartPoints(
    Iterable<SalesLiveMapPoint> points,
  ) {
    return points.map(toChartPoint).toList(growable: false);
  }

  static int pointsContentDigest(Iterable<SalesLiveMapPoint> points) {
    final pointList = points is List<SalesLiveMapPoint>
        ? points
        : points.toList(growable: false);
    var h = Object.hash(_kSalesLiveMapPointsDigestSeed, pointList.length);
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
        point.locationResolution,
        point.subtitle ?? '',
      );
    }
    return h;
  }
}
