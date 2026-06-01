import 'package:colmeia/features/sales/domain/entities/sales_live_map_metric.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/features/sales/presentation/localization/sales_live_map_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
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

  static AppBrazilStoreSalesPoint toChartPoint(
    SalesLiveMapPoint point,
    AppLocalizations l10n,
  ) {
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
      subtitle: _resolveSubtitle(point, l10n),
      payload: point.payload,
    );
  }

  static List<AppBrazilStoreSalesPoint> toChartPoints(
    Iterable<SalesLiveMapPoint> points,
    AppLocalizations l10n,
  ) {
    return points
        .map((point) => toChartPoint(point, l10n))
        .toList(growable: false);
  }

  static String? _resolveSubtitle(
    SalesLiveMapPoint point,
    AppLocalizations l10n,
  ) {
    final agentName = point.agentName;
    final companyCode = point.companyCode;
    final branchCode = point.branchCode;
    if (agentName == null || companyCode == null || branchCode == null) {
      return point.subtitle;
    }
    return SalesLiveMapL10n.branchPointSubtitle(
      l10n,
      agentName: agentName,
      companyCode: companyCode,
      branchCode: branchCode,
    );
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
