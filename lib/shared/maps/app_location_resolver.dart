import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_map_static_data.dart';

abstract interface class AppLocationGeocoder {
  String get providerId;

  Future<AppResolvedLocation?> resolve(AppLocationLookupInput input);
}

class AppLocationResolver {
  const AppLocationResolver({
    required AppLocationGeocodeCache cache,
    AppLocationGeocoder? geocoder,
    List<AppLocationGeocoder> geocoders = const <AppLocationGeocoder>[],
    DateTime Function()? now,
  }) : _cache = cache,
       _geocoder = geocoder,
       _geocoders = geocoders,
       _now = now;

  final AppLocationGeocodeCache _cache;
  final AppLocationGeocoder? _geocoder;
  final List<AppLocationGeocoder> _geocoders;
  final DateTime Function()? _now;

  Future<AppResolvedLocation?> resolve(AppLocationLookupInput input) async {
    final providedPoint = input.geoPoint;
    if (input.type == AppLocationLookupType.geoPoint &&
        providedPoint != null &&
        providedPoint.isValid) {
      return AppResolvedLocation(
        point: providedPoint,
        precision: AppLocationPrecision.exact,
        source: AppLocationSource.provided,
        cacheKey: 'provided_geo_point',
        resolvedAt: _resolveNow(),
      );
    }

    final cacheKey = AppLocationLookupNormalizer.cacheKeyFor(input);
    if (cacheKey == null) {
      return null;
    }

    if (_isStaticLocalLookup(input.type)) {
      final resolved = await _resolveWithGeocoders(input, cacheKey);
      if (resolved != null) {
        if (_shouldPersist(resolved)) {
          await _cache.write(resolved);
        }
        return resolved;
      }

      if (input.type == AppLocationLookupType.uf) {
        return _resolveBrazilStateCentroid(input.uf, cacheKey);
      }

      return null;
    }

    final cached = await _cache.read(cacheKey);
    if (cached != null && cached.point.isValid) {
      return cached.copyWith(source: AppLocationSource.cache);
    }

    final resolved = await _resolveWithGeocoders(input, cacheKey);
    if (resolved != null && resolved.point.isValid) {
      if (_shouldPersist(resolved)) {
        await _cache.write(resolved);
      }
      return resolved;
    }

    if (input.type == AppLocationLookupType.uf) {
      return _resolveBrazilStateCentroid(input.uf, cacheKey);
    }

    return null;
  }

  Future<AppResolvedLocation?> _resolveWithGeocoders(
    AppLocationLookupInput input,
    String cacheKey,
  ) async {
    final geocoders = <AppLocationGeocoder>[
      ..._geocoders,
      if (_geocoder != null) _geocoder,
    ];
    for (final geocoder in geocoders) {
      final resolved = await geocoder.resolve(input);
      if (resolved != null && resolved.point.isValid) {
        return resolved.copyWith(
          cacheKey: cacheKey,
          resolvedAt: resolved.resolvedAt ?? _resolveNow(),
        );
      }
    }

    return null;
  }

  DateTime _resolveNow() {
    return (_now ?? DateTime.now)();
  }

  AppResolvedLocation? _resolveBrazilStateCentroid(
    String? uf,
    String cacheKey,
  ) {
    final normalizedUf = AppLocationLookupNormalizer.normalizeUf(uf);
    if (normalizedUf == null) {
      return null;
    }

    final centroid = AppBrazilMapStaticData.stateCentroidsByUf[normalizedUf];
    if (centroid == null) {
      return null;
    }

    return AppResolvedLocation(
      point: AppGeoPoint(
        latitude: centroid.latitude,
        longitude: centroid.longitude,
      ),
      precision: AppLocationPrecision.stateCentroid,
      source: AppLocationSource.staticBrazilStateCentroid,
      cacheKey: cacheKey,
      label: AppBrazilMapStaticData.stateNameForUf(normalizedUf),
      resolvedAt: _resolveNow(),
    );
  }

  bool _isStaticLocalLookup(AppLocationLookupType type) {
    return switch (type) {
      AppLocationLookupType.ibgeMunicipalityCode ||
      AppLocationLookupType.cityUf ||
      AppLocationLookupType.capitalUf ||
      AppLocationLookupType.uf => true,
      AppLocationLookupType.geoPoint || AppLocationLookupType.cep => false,
    };
  }

  bool _shouldPersist(AppResolvedLocation location) {
    return switch (location.source) {
      AppLocationSource.staticBrazilMunicipalityCentroid ||
      AppLocationSource.staticBrazilStateCentroid ||
      AppLocationSource.provided ||
      AppLocationSource.cache => false,
      AppLocationSource.geocodingProvider => true,
    };
  }
}
