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
  Future<AppResolvedLocation?> resolve(AppLocationLookupInput input) async {
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
      AppLocationLookupType.geoPoint ||
      AppLocationLookupType.cep ||
      AppLocationLookupType.uf => null,
    };
    if (centroid == null) {
      return null;
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
      AppLocationLookupType.capitalUf =>
        AppLocationLookupNormalizer.cacheKeyForCapitalUf(centroid.uf),
      AppLocationLookupType.geoPoint ||
      AppLocationLookupType.cep ||
      AppLocationLookupType.uf => null,
    };
    if (cacheKey == null) {
      return null;
    }

    return AppResolvedLocation(
      point: centroid.point,
      precision: AppLocationPrecision.city,
      source: AppLocationSource.staticBrazilMunicipalityCentroid,
      cacheKey: cacheKey,
      label: '${centroid.name} / ${centroid.uf}',
      metadata: <String, Object?>{
        'ibgeCode': centroid.ibgeCode,
        'city': centroid.name,
        'ufCode': centroid.ufCode,
        'uf': centroid.uf,
        'stateName': centroid.stateName,
        'region': centroid.region,
        'isCapital': centroid.isCapital,
        'siafiId': centroid.siafiId,
        'ddd': centroid.ddd,
        'timezone': centroid.timezone,
      },
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
