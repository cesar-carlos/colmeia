import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

typedef AppAddressLocationsLookup = Future<List<geocoding.Location>> Function(
  String query,
);

typedef AppGeocodingFactory = geocoding.Geocoding Function();

class AppGeocodingPluginGeocoder implements AppLocationGeocoder {
  AppGeocodingPluginGeocoder({
    AppAddressLocationsLookup? lookupLocations,
    AppGeocodingFactory? createGeocoding,
  }) : _lookupLocations =
           lookupLocations ??
           ((query) => (createGeocoding ?? geocoding.Geocoding.new)()
               .locationFromAddress(query));

  final AppAddressLocationsLookup _lookupLocations;

  @override
  String get providerId => 'geocoding_plugin';

  @override
  bool get isExternal => true;

  @override
  int get maxConcurrentRequests => 1;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    final query = switch (input.type) {
      AppLocationLookupType.streetAddress =>
        input.postalAddress?.toFreeFormQuery(),
      AppLocationLookupType.cep => AppLocationLookupNormalizer.normalizeCep(
        input.cep,
      ),
      AppLocationLookupType.geoPoint ||
      AppLocationLookupType.ibgeMunicipalityCode ||
      AppLocationLookupType.cityUf ||
      AppLocationLookupType.capitalUf ||
      AppLocationLookupType.uf => null,
    };
    if (query == null || query.trim().isEmpty) {
      return const AppLocationGeocoderResult.unsupported();
    }

    try {
      final locations = await _lookupLocations(query);
      if (locations.isEmpty) {
        return const AppLocationGeocoderResult.notFound();
      }

      final first = locations.first;
      final point = AppGeoPoint(
        latitude: first.latitude,
        longitude: first.longitude,
      );
      if (!point.isValid) {
        return const AppLocationGeocoderResult.notFound();
      }

      final postalAddress = input.postalAddress;
      return AppLocationGeocoderResult.resolved(
        AppResolvedLocation(
          point: point,
          precision: input.type == AppLocationLookupType.cep
              ? AppLocationPrecision.cep
              : AppLocationPrecision.exact,
          source: AppLocationSource.geocodingProvider,
          cacheKey: '',
          label: _labelForInput(input),
          details: AppResolvedAddressDetails(
            city: _trimmed(postalAddress?.city),
            uf: AppLocationLookupNormalizer.normalizeUf(postalAddress?.uf),
            cep: AppLocationLookupNormalizer.normalizeCep(postalAddress?.cep),
            countryCode: AppLocationLookupNormalizer.normalizeCountryCodeLoose(
              postalAddress?.countryCode,
            ),
          ),
          metadata: <String, Object?>{
            'provider': providerId,
          },
        ),
      );
    } on PlatformException catch (error) {
      if (error.code == 'IO_ERROR') {
        return AppLocationGeocoderResult.transientFailure(
          message: error.message,
        );
      }
      return AppLocationGeocoderResult.transientFailure(
        message: error.message ?? error.code,
      );
    }
  }

  String? _trimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? _labelForInput(AppLocationLookupInput input) {
    if (input.type == AppLocationLookupType.cep) {
      return AppLocationLookupNormalizer.normalizeCep(input.cep);
    }

    final address = input.postalAddress;
    if (address == null) {
      return null;
    }
    final city = address.city?.trim();
    final uf = address.uf?.trim().toUpperCase();
    if (city != null && city.isNotEmpty && uf != null && uf.isNotEmpty) {
      return '$city / $uf';
    }
    return null;
  }
}
