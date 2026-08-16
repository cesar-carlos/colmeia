import 'package:colmeia/shared/maps/app_geocoding_plugin_geocoder.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

void main() {
  group('AppGeocodingPluginGeocoder', () {
    test('resolves a street address into an exact location', () async {
      var capturedQuery = '';
      final geocoder = AppGeocodingPluginGeocoder(
        lookupLocations: (query) async {
          capturedQuery = query;
          return <geocoding.Location>[
            geocoding.Location(
              latitude: -11.8604,
              longitude: -55.5091,
              timestamp: DateTime.utc(2026, 5, 18),
            ),
          ];
        },
      );

      final result = await geocoder.resolve(
        const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            street: 'Rua das Flores',
            number: '123',
            district: 'Centro',
            city: 'Sinop',
            uf: 'MT',
            cep: '78550005',
          ),
        ),
      );

      expect(
        capturedQuery,
        'Rua das Flores, 123, Centro, Sinop, MT, 78550005, BR',
      );
      expect(result.type, AppLocationGeocoderResultType.resolved);
      expect(result.location?.precision, AppLocationPrecision.exact);
      expect(result.location?.label, 'Sinop / MT');
      expect(result.location?.details?.city, 'Sinop');
      expect(result.location?.details?.uf, 'MT');
      expect(result.location?.details?.cep, '78550005');
    });

    test('returns notFound when plugin reports no result', () async {
      final geocoder = AppGeocodingPluginGeocoder(
        lookupLocations: (_) async => const <geocoding.Location>[],
      );

      final result = await geocoder.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );

      expect(result.type, AppLocationGeocoderResultType.notFound);
      expect(result.location, isNull);
    });

    test('maps IO_ERROR into transient failure', () async {
      final geocoder = AppGeocodingPluginGeocoder(
        lookupLocations: (_) async => throw PlatformException(
          code: 'IO_ERROR',
          message: 'rate-limited',
        ),
      );

      final result = await geocoder.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );

      expect(result.type, AppLocationGeocoderResultType.transientFailure);
      expect(result.message, 'rate-limited');
    });

    test('returns unsupported for unsupported lookup types', () async {
      final geocoder = AppGeocodingPluginGeocoder(
        lookupLocations: (_) async => <geocoding.Location>[],
      );

      final result = await geocoder.resolve(
        const AppLocationLookupInput.ibgeMunicipalityCode(
          ibgeMunicipalityCode: '5107909',
        ),
      );

      expect(result.type, AppLocationGeocoderResultType.unsupported);
    });
  });
}
