import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/maps/resolve_postal_address_location_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResolvePostalAddressLocationUseCase', () {
    test('returns resolved location with convenience fields', () async {
      final useCase = ResolvePostalAddressLocationUseCase(
        AppLocationResolver(
          cache: AppLocationGeocodeCache(_MemoryCacheStore()),
          geocoder: _FakeGeocoder(
            result: const AppLocationGeocoderResult.resolved(
              AppResolvedLocation(
                point: AppGeoPoint(latitude: -11.8604, longitude: -55.5091),
                precision: AppLocationPrecision.exact,
                source: AppLocationSource.geocodingProvider,
                cacheKey: '',
                details: AppResolvedAddressDetails(
                  city: 'Sinop',
                  uf: 'MT',
                  countryCode: 'BR',
                ),
              ),
            ),
          ),
        ),
      );

      final result = await useCase(
        const AppPostalAddress(
          street: 'Rua das Flores',
          number: '123',
          city: 'Sinop',
          uf: 'MT',
          cep: '78550005',
        ),
      );

      expect(result.isSuccess(), isTrue);
      final resolved = result.getOrNull();
      expect(resolved?.found, isTrue);
      expect(resolved?.latitude, -11.8604);
      expect(resolved?.longitude, -55.5091);
      expect(resolved?.city, 'Sinop');
      expect(resolved?.uf, 'MT');
    });

    test('returns notFound for empty address without provider call', () async {
      final geocoder = _FakeGeocoder(
        result: const AppLocationGeocoderResult.notFound(),
      );
      final useCase = ResolvePostalAddressLocationUseCase(
        AppLocationResolver(
          cache: AppLocationGeocodeCache(_MemoryCacheStore()),
          geocoder: geocoder,
        ),
      );

      final result = await useCase(const AppPostalAddress());

      expect(result.isSuccess(), isTrue);
      expect(result.getOrNull()?.found, isFalse);
      expect(geocoder.calls, 0);
    });

    test('returns notFound when resolver does not find location', () async {
      final useCase = ResolvePostalAddressLocationUseCase(
        AppLocationResolver(
          cache: AppLocationGeocodeCache(_MemoryCacheStore()),
          geocoder: _FakeGeocoder(
            result: const AppLocationGeocoderResult.notFound(),
          ),
        ),
      );

      final result = await useCase(
        const AppPostalAddress(
          street: 'Rua das Flores',
          city: 'Sinop',
          uf: 'MT',
        ),
      );

      expect(result.isSuccess(), isTrue);
      expect(result.getOrNull()?.found, isFalse);
      expect(result.getOrNull()?.location, isNull);
    });

    test('propagates transient resolver failures', () async {
      final useCase = ResolvePostalAddressLocationUseCase(
        AppLocationResolver(
          cache: AppLocationGeocodeCache(_MemoryCacheStore()),
          geocoder: _FakeGeocoder(
            result: const AppLocationGeocoderResult.transientFailure(
              message: 'rate-limited',
            ),
          ),
        ),
      );

      final result = await useCase(
        const AppPostalAddress(
          street: 'Rua das Flores',
          city: 'Sinop',
          uf: 'MT',
        ),
      );

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull()?.isTransient, isTrue);
    });
  });
}

class _MemoryCacheStore implements AppCacheStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> clearAll() async {
    _values.clear();
  }

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> putString({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    _values.remove(key);
  }
}

class _FakeGeocoder implements AppLocationGeocoder {
  _FakeGeocoder({required this.result});

  final AppLocationGeocoderResult result;
  int calls = 0;

  @override
  String get providerId => 'fake';

  @override
  bool get isExternal => false;

  @override
  int get maxConcurrentRequests => 1;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    calls += 1;
    return result;
  }
}
