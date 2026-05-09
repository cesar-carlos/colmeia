import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';

class AppBrazilStoreSalesPointSource {
  const AppBrazilStoreSalesPointSource({
    required this.id,
    required this.name,
    required this.salesAmount,
    required this.salesCount,
    this.uf,
    this.city,
    this.latitude,
    this.longitude,
    this.ibgeMunicipalityCode,
    this.preferCapitalFallback = false,
    this.subtitle,
    this.payload,
  });

  final String id;
  final String name;
  final double salesAmount;
  final int salesCount;
  final String? uf;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? ibgeMunicipalityCode;
  final bool preferCapitalFallback;
  final String? subtitle;
  final Object? payload;
}

class AppBrazilStoreSalesPointResolver {
  const AppBrazilStoreSalesPointResolver({
    required AppLocationResolver locationResolver,
  }) : _locationResolver = locationResolver;

  final AppLocationResolver _locationResolver;

  Future<AppBrazilStoreSalesPoint?> resolve(
    AppBrazilStoreSalesPointSource source,
  ) async {
    final input = _lookupInputFor(source);
    if (input == null) {
      return null;
    }

    final location = await _locationResolver.resolve(input);
    if (location == null || !location.point.isValid) {
      return null;
    }

    final uf = _resolveUf(source, location);
    if (uf == null) {
      return null;
    }
    final municipalityCode =
        AppLocationLookupNormalizer.normalizeIbgeMunicipalityCode(
          source.ibgeMunicipalityCode,
        );

    return AppBrazilStoreSalesPoint(
      id: source.id,
      name: source.name,
      uf: uf,
      latitude: location.point.latitude,
      longitude: location.point.longitude,
      salesAmount: source.salesAmount,
      salesCount: source.salesCount,
      municipalityCode: municipalityCode,
      city: _resolveCity(source, location),
      subtitle: source.subtitle,
      payload: source.payload,
    );
  }

  Future<List<AppBrazilStoreSalesPoint>> resolveAll(
    Iterable<AppBrazilStoreSalesPointSource> sources,
  ) async {
    final points = <AppBrazilStoreSalesPoint>[];
    for (final source in sources) {
      final point = await resolve(source);
      if (point != null) {
        points.add(point);
      }
    }

    return points;
  }

  AppLocationLookupInput? _lookupInputFor(
    AppBrazilStoreSalesPointSource source,
  ) {
    final latitude = source.latitude;
    final longitude = source.longitude;
    final uf = AppLocationLookupNormalizer.normalizeUf(source.uf);
    if (latitude != null &&
        longitude != null &&
        uf != null &&
        AppGeoPoint(latitude: latitude, longitude: longitude).isValid) {
      return AppLocationLookupInput.geoPoint(
        geoPoint: AppGeoPoint(latitude: latitude, longitude: longitude),
      );
    }

    final ibgeCode = AppLocationLookupNormalizer.normalizeIbgeMunicipalityCode(
      source.ibgeMunicipalityCode,
    );
    if (ibgeCode != null) {
      return AppLocationLookupInput.ibgeMunicipalityCode(
        ibgeMunicipalityCode: ibgeCode,
      );
    }

    final city = AppLocationLookupNormalizer.normalizeCity(source.city);
    if (city != null && uf != null) {
      return AppLocationLookupInput.cityUf(city: source.city!, uf: uf);
    }

    if (source.preferCapitalFallback && uf != null) {
      return AppLocationLookupInput.capitalUf(uf: uf);
    }

    if (uf != null) {
      return AppLocationLookupInput.uf(uf: uf);
    }

    return null;
  }

  String? _resolveUf(
    AppBrazilStoreSalesPointSource source,
    AppResolvedLocation location,
  ) {
    final metadataUf = location.metadata['uf'];
    if (metadataUf is String) {
      final normalizedUf = AppLocationLookupNormalizer.normalizeUf(metadataUf);
      if (normalizedUf != null) {
        return normalizedUf;
      }
    }

    return AppLocationLookupNormalizer.normalizeUf(source.uf);
  }

  String? _resolveCity(
    AppBrazilStoreSalesPointSource source,
    AppResolvedLocation location,
  ) {
    final city = source.city?.trim();
    if (city != null && city.isNotEmpty) {
      return city;
    }

    final metadataCity = location.metadata['city'];
    if (metadataCity is String && metadataCity.trim().isNotEmpty) {
      return metadataCity.trim();
    }

    return null;
  }
}
