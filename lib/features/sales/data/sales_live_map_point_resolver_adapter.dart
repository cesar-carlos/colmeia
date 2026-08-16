import 'package:colmeia/features/sales/domain/contracts/sales_live_map_point_resolver.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';

class SalesLiveMapPointResolverAdapter implements SalesLiveMapPointResolver {
  const SalesLiveMapPointResolverAdapter({
    required this._delegate,
  });

  final AppBrazilStoreSalesPointResolver _delegate;

  @override
  Future<SalesLiveMapPoint?> resolve(SalesLiveMapPointSource source) async {
    final resolved = await _delegate.resolve(_toSharedSource(source));
    if (resolved == null) {
      return null;
    }
    return _fromSharedPoint(resolved);
  }

  @override
  Future<SalesLiveMapResolvedPoint?> resolveWithDetails(
    SalesLiveMapPointSource source,
  ) async {
    final resolved = await _delegate.resolveWithDetails(
      _toSharedSource(source),
    );
    if (resolved == null) {
      return null;
    }
    return SalesLiveMapResolvedPoint(
      point: _fromSharedPoint(resolved.point),
    );
  }

  @override
  Future<List<SalesLiveMapPoint>> resolveAll(
    Iterable<SalesLiveMapPointSource> sources,
  ) async {
    final resolved = await _delegate.resolveAll(
      sources.map(_toSharedSource),
    );
    return resolved.map(_fromSharedPoint).toList(growable: false);
  }

  @override
  Future<List<SalesLiveMapResolvedPoint>> resolveAllWithDetails(
    Iterable<SalesLiveMapPointSource> sources, {
    int maxConcurrent = 1,
  }) async {
    final resolved = await _delegate.resolveAllWithDetails(
      sources.map(_toSharedSource),
      maxConcurrent: maxConcurrent,
    );
    return _toResolvedPoints(resolved);
  }

  @override
  Future<List<SalesLiveMapResolvedPoint>> resolveAllSqlMunicipalityWithDetails(
    Iterable<SalesLiveMapPointSource> sources, {
    int maxConcurrent = 1,
  }) async {
    final resolved = await _delegate.resolveAllSqlMunicipalityWithDetails(
      sources.map(_toSharedSource),
      maxConcurrent: maxConcurrent,
    );
    return _toResolvedPoints(resolved);
  }

  List<SalesLiveMapResolvedPoint> _toResolvedPoints(
    List<AppBrazilStoreSalesResolvedPoint> resolved,
  ) {
    return resolved
        .map(
          (item) => SalesLiveMapResolvedPoint(
            point: _fromSharedPoint(item.point),
          ),
        )
        .toList(growable: false);
  }

  AppBrazilStoreSalesPointSource _toSharedSource(
    SalesLiveMapPointSource source,
  ) {
    return AppBrazilStoreSalesPointSource(
      id: source.id,
      name: source.name,
      salesAmount: source.salesAmount,
      salesCount: source.salesCount,
      uf: source.uf,
      city: source.city,
      latitude: source.latitude,
      longitude: source.longitude,
      cep: source.cep,
      ibgeMunicipalityCode: source.ibgeMunicipalityCode,
      preferCapitalFallback: source.preferCapitalFallback,
      allowUfFallback: source.allowUfFallback,
      fantasyName: source.fantasyName,
      branchName: source.branchName,
      companyCode: source.companyCode,
      branchCode: source.branchCode,
      agentName: source.agentName,
      salesDataLoading: source.salesDataLoading,
      salesDataUnavailable: source.salesDataUnavailable,
      salesDataStatusLabel: source.salesDataStatusLabel,
      subtitle: source.subtitle,
      payload: source.payload,
    );
  }

  SalesLiveMapPoint _fromSharedPoint(AppBrazilStoreSalesPoint point) {
    return SalesLiveMapPoint(
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
        AppBrazilStoreSalesLocationResolution.providedGeoPoint =>
          SalesLiveMapLocationResolution.providedGeoPoint,
        AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode =>
          SalesLiveMapLocationResolution.ibgeMunicipalityCode,
        AppBrazilStoreSalesLocationResolution.cep =>
          SalesLiveMapLocationResolution.cep,
        AppBrazilStoreSalesLocationResolution.cityUf =>
          SalesLiveMapLocationResolution.cityUf,
        AppBrazilStoreSalesLocationResolution.capitalUf =>
          SalesLiveMapLocationResolution.capitalUf,
        AppBrazilStoreSalesLocationResolution.stateUf =>
          SalesLiveMapLocationResolution.stateUf,
        null => null,
      },
      subtitle: point.subtitle,
      payload: point.payload,
    );
  }
}
