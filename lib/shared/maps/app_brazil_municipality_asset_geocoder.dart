import 'package:colmeia/shared/maps/app_brazil_municipality_centroid_index.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';

class AppBrazilMunicipalityAssetGeocoder implements AppLocationGeocoder {
  const AppBrazilMunicipalityAssetGeocoder({
    Future<AppBrazilMunicipalityCentroidIndex> Function()? indexLoader,
  }) : _indexLoader = indexLoader;

  final Future<AppBrazilMunicipalityCentroidIndex> Function()? _indexLoader;

  static Future<AppBrazilMunicipalityCentroidIndex>? _sharedIndexFuture;

  @override
  String get providerId => 'brazil_municipality_asset';

  @override
  bool get isExternal => false;

  @override
  int get maxConcurrentRequests => 1;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    final index = await _loadIndex();
    final centroid = switch (input.type) {
      AppLocationLookupType.ibgeMunicipalityCode => index.lookupByIbgeCode(
        input.ibgeMunicipalityCode,
      ),
      AppLocationLookupType.cityUf => index.lookupByCityUf(
        city: input.city,
        uf: input.uf,
      ),
      AppLocationLookupType.capitalUf => index.lookupCapitalByUf(input.uf),
      AppLocationLookupType.streetAddress => null,
      AppLocationLookupType.geoPoint ||
      AppLocationLookupType.cep ||
      AppLocationLookupType.uf => null,
    };
    if (centroid == null) {
      return switch (input.type) {
        AppLocationLookupType.ibgeMunicipalityCode ||
        AppLocationLookupType.cityUf ||
        AppLocationLookupType.capitalUf =>
          const AppLocationGeocoderResult.notFound(),
        AppLocationLookupType.streetAddress ||
        AppLocationLookupType.geoPoint ||
        AppLocationLookupType.cep ||
        AppLocationLookupType.uf =>
          const AppLocationGeocoderResult.unsupported(),
      };
    }

    final cacheKey = switch (input.type) {
      AppLocationLookupType.ibgeMunicipalityCode =>
        AppLocationLookupNormalizer.cacheKeyForIbgeMunicipality(
          centroid.ibgeCode,
        ),
      AppLocationLookupType.cityUf =>
        AppLocationLookupNormalizer.cacheKeyForCityUf(
          city: centroid.name,
          uf: centroid.uf,
        ),
      AppLocationLookupType.streetAddress => null,
      AppLocationLookupType.capitalUf =>
        AppLocationLookupNormalizer.cacheKeyForCapitalUf(centroid.uf),
      AppLocationLookupType.geoPoint ||
      AppLocationLookupType.cep ||
      AppLocationLookupType.uf => null,
    };
    if (cacheKey == null) {
      return const AppLocationGeocoderResult.unsupported();
    }

    return AppLocationGeocoderResult.resolved(
      AppResolvedLocation(
        point: centroid.point,
        precision: AppLocationPrecision.city,
        source: AppLocationSource.staticBrazilMunicipalityCentroid,
        cacheKey: cacheKey,
        label: '${centroid.name} / ${centroid.uf}',
        details: AppResolvedAddressDetails(
          city: centroid.name,
          uf: centroid.uf,
          countryCode: 'BR',
        ),
        metadata: <String, Object?>{
          'ibgeCode': centroid.ibgeCode,
          'ufCode': centroid.ufCode,
          'stateName': centroid.stateName,
          'region': centroid.region,
          'isCapital': centroid.isCapital,
          'siafiId': centroid.siafiId,
          'ddd': centroid.ddd,
          'timezone': centroid.timezone,
        },
      ),
    );
  }

  Future<AppBrazilMunicipalityCentroidIndex> _loadIndex() {
    final loader = _indexLoader;
    if (loader != null) {
      return loader();
    }

    return _sharedIndexFuture ??=
        AppBrazilMunicipalityCentroidIndex.loadFromAsset();
  }
}
