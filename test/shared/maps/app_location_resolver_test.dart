import 'dart:convert';
import 'dart:io';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_asset_geocoder.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_centroid_index.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolution_observer.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocationLookupNormalizer', () {
    test('normalizes CEP, city and UF into stable cache keys', () {
      expect(
        AppLocationLookupNormalizer.cacheKeyForCep('78.550-005'),
        'location_geocode_cep_78550005',
      );
      expect(
        AppLocationLookupNormalizer.cacheKeyForCityUf(
          city: ' Sao Jose do Rio Preto ',
          uf: ' sp ',
        ),
        'location_geocode_city_uf_SAO_JOSE_DO_RIO_PRETO_SP',
      );
      expect(
        AppLocationLookupNormalizer.cacheKeyForCityUf(
          city: ' Tangara da Serra ',
          uf: 'mt',
        ),
        'location_geocode_city_uf_TANGARA_DA_SERRA_MT',
      );
      expect(
        AppLocationLookupNormalizer.normalizeCountryCodeLoose('BRA'),
        'BR',
      );
    });

    test('builds a hashed and stable key for street address', () {
      final first = AppLocationLookupNormalizer.cacheKeyForStreetAddress(
        const AppPostalAddress(
          street: ' Rua das Flores ',
          number: '123',
          district: 'Centro',
          city: 'Sinop',
          uf: 'mt',
          cep: '78.550-005',
        ),
      );
      final second = AppLocationLookupNormalizer.cacheKeyForStreetAddress(
        const AppPostalAddress(
          street: 'rua das flores',
          number: '123',
          district: 'centro',
          city: 'SINOP',
          uf: 'MT',
          cep: '78550005',
        ),
      );

      expect(first, isNotNull);
      expect(second, first);
      expect(first, contains('street_address_v1_'));
      expect(first, isNot(contains('RUA_DAS_FLORES')));
    });
  });

  group('AppBrazilMunicipalityCentroidIndex', () {
    test('parses CSV and preserves longitude/latitude order', () {
      final index = AppBrazilMunicipalityCentroidIndex.parse(
        _municipalityCsv(<String>[
          '1100015',
          "Alta Floresta D'Oeste",
          '11',
          'RO',
          'Rondonia',
          'Norte',
          '0',
          '-11.9283',
          '-61.9953',
          '0033',
          '69',
          'America/Porto_Velho',
        ]),
      );

      final centroid = index.lookupByIbgeCode('1100015');

      expect(centroid?.name, "Alta Floresta D'Oeste");
      expect(centroid?.longitude, -61.9953);
      expect(centroid?.latitude, -11.9283);
    });

    test('loads full municipality asset', () {
      final file = File(AppBrazilMunicipalityCentroidIndex.assetPath);
      final index = AppBrazilMunicipalityCentroidIndex.parse(
        file.readAsStringSync(),
      );

      expect(index.length, 5571);
      expect(index.lookupByIbgeCode('5107958')?.uf, 'MT');
    });
  });

  group('AppLocationGeocodeCache', () {
    test('round-trips resolved locations in the versioned envelope', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      const location = AppResolvedLocation(
        point: AppGeoPoint(latitude: -11.86, longitude: -55.50),
        precision: AppLocationPrecision.city,
        source: AppLocationSource.geocodingProvider,
        cacheKey: 'location_geocode_city_uf_SINOP_MT',
        label: 'Sinop / MT',
        details: AppResolvedAddressDetails(
          city: 'Sinop',
          uf: 'MT',
          countryCode: 'BR',
        ),
        metadata: <String, Object?>{'ibgeCode': '5107909'},
      );

      await cache.writeResolved(
        location,
        lookupType: AppLocationLookupType.streetAddress,
        providerId: 'fake',
        createdAt: DateTime.utc(2026, 5),
      );
      final entry = await cache.readEntry(location.cacheKey);

      expect(entry?.isResolved, isTrue);
      expect(entry?.providerId, 'fake');
      expect(entry?.location?.point.latitude, -11.86);
      expect(entry?.location?.details?.city, 'Sinop');
      expect(
        store.values.keys.any(
          (key) => key.startsWith(AppKvCacheKeyPrefixes.locationGeocodeEntry),
        ),
        isTrue,
      );
      expect(store.values.containsKey(location.cacheKey), isFalse);
    });

    test('uses distinct TTL policies for street address and CEP', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      const streetKey =
          'location_geocode_street_address_v1_deadbeefdeadbeefdeadbeef';
      const cepKey = 'location_geocode_cep_01001000';
      const location = AppResolvedLocation(
        point: AppGeoPoint(latitude: -23.55, longitude: -46.63),
        precision: AppLocationPrecision.exact,
        source: AppLocationSource.geocodingProvider,
        cacheKey: '',
      );
      final createdAt = DateTime.utc(2026, 5);

      await cache.writeResolved(
        location.copyWith(cacheKey: streetKey),
        lookupType: AppLocationLookupType.streetAddress,
        providerId: 'fake',
        createdAt: createdAt,
      );
      await cache.writeResolved(
        location.copyWith(cacheKey: cepKey),
        lookupType: AppLocationLookupType.cep,
        providerId: 'fake',
        createdAt: createdAt,
      );

      final streetEntry = await cache.readEntry(streetKey);
      final cepEntry = await cache.readEntry(cepKey);

      expect(
        streetEntry?.expiresAt,
        createdAt.add(
          AppLocationGeocodeCache.defaultStreetAddressResolvedTtl,
        ),
      );
      expect(
        cepEntry?.expiresAt,
        createdAt.add(AppLocationGeocodeCache.defaultCepResolvedTtl),
      );
    });

    test('round-trips negative cache entries', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);

      await cache.writeNotFound(
        cacheKey: 'location_geocode_street_address_v1_deadbeef',
        lookupType: AppLocationLookupType.streetAddress,
        providerId: 'fake',
        createdAt: DateTime.utc(2026, 5),
      );
      final entry = await cache.readEntry(
        'location_geocode_street_address_v1_deadbeef',
      );

      expect(entry?.isNotFound, isTrue);
      expect(entry?.providerId, 'fake');
      expect(entry?.location, isNull);
    });

    test('purges expired entries and orphaned index records', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      const key = 'location_geocode_street_address_v1_expired';
      await cache.writeNotFound(
        cacheKey: key,
        lookupType: AppLocationLookupType.streetAddress,
        providerId: 'fake',
        createdAt: DateTime.utc(2026, 5),
      );

      const indexKey = AppKvCacheKeyPrefixes.locationGeocodeIndex;
      final index = jsonDecode(store.values[indexKey]!) as List<dynamic>;
      const orphanStorageKey = 'location_geocode_entry_orphaned_hash';
      store.values[indexKey] = jsonEncode(<String>[
        ...index.whereType<String>(),
        orphanStorageKey,
      ]);

      final summary = await cache.purgeExpiredEntries(
        now: DateTime.utc(2026, 9),
      );

      expect(summary.scannedEntries, 2);
      expect(summary.removedExpiredEntries, 1);
      expect(summary.removedOrphanedIndexEntries, 1);
      expect(summary.remainingIndexedEntries, 0);
      expect(await cache.readEntry(key), isNull);
    });

    test('reads legacy cached resolved location payloads', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      const key = 'location_geocode_cep_01001000';
      store.values[key] = jsonEncode(
        const AppResolvedLocation(
          point: AppGeoPoint(latitude: -23.55, longitude: -46.63),
          precision: AppLocationPrecision.cep,
          source: AppLocationSource.geocodingProvider,
          cacheKey: key,
        ).toJson(),
      );

      final entry = await cache.readEntry(key);

      expect(entry?.isResolved, isTrue);
      expect(entry?.providerId, 'legacy');
      expect(entry?.location?.point.latitude, -23.55);
    });
  });

  group('AppLocationResolver', () {
    test('returns valid provided geo point without cache lookup', () async {
      final store = _FakeCacheStore();
      final resolver = AppLocationResolver(
        cache: AppLocationGeocodeCache(store),
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.geoPoint(
          geoPoint: AppGeoPoint(latitude: -15.6, longitude: -56.1),
        ),
      );

      expect(result.isSuccess(), isTrue);
      final outcome = result.getOrNull();
      expect(outcome, isA<AppLocationResolutionResolved>());
      final resolved = outcome;
      if (resolved is! AppLocationResolutionResolved) {
        fail('Expected resolved outcome.');
      }
      expect(
        resolved.location.source,
        AppLocationSource.provided,
      );
      expect(store.values, isEmpty);
    });

    test('returns cached CEP location before calling geocoder', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      final key = AppLocationLookupNormalizer.cacheKeyForCep('01001-000')!;
      await cache.writeResolved(
        AppResolvedLocation(
          point: const AppGeoPoint(latitude: -11.86, longitude: -55.50),
          precision: AppLocationPrecision.city,
          source: AppLocationSource.geocodingProvider,
          cacheKey: key,
          resolvedAt: DateTime.utc(2026),
        ),
        lookupType: AppLocationLookupType.cep,
        providerId: 'fake',
        createdAt: DateTime.utc(2026),
      );
      final geocoder = _FakeGeocoder(
        result: AppLocationGeocoderResult.resolved(
          AppResolvedLocation(
            point: const AppGeoPoint(latitude: -1, longitude: -1),
            precision: AppLocationPrecision.city,
            source: AppLocationSource.geocodingProvider,
            cacheKey: key,
          ),
        ),
      );
      final resolver = AppLocationResolver(
        cache: cache,
        geocoder: geocoder,
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );

      final outcome = result.getOrNull();
      expect(outcome, isA<AppLocationResolutionResolved>());
      final resolved = outcome;
      if (resolved is! AppLocationResolutionResolved) {
        fail('Expected resolved outcome.');
      }
      expect(
        resolved.location.source,
        AppLocationSource.cache,
      );
      expect(geocoder.calls, 0);
    });

    test(
      'resolves IBGE code from local municipality asset before external',
      () async {
        final store = _FakeCacheStore();
        final localGeocoder = AppBrazilMunicipalityAssetGeocoder(
          indexLoader: () async => AppBrazilMunicipalityCentroidIndex.parse(
            _municipalityCsv(<String>[
              '1100015',
              "Alta Floresta D'Oeste",
              '11',
              'RO',
              'Rondonia',
              'Norte',
              '0',
              '-11.9283',
              '-61.9953',
              '0033',
              '69',
              'America/Porto_Velho',
            ]),
          ),
        );
        final externalGeocoder = _FakeGeocoder(
          result: const AppLocationGeocoderResult.resolved(
            AppResolvedLocation(
              point: AppGeoPoint(latitude: -1, longitude: -1),
              precision: AppLocationPrecision.city,
              source: AppLocationSource.geocodingProvider,
              cacheKey: 'ignored',
            ),
          ),
        );
        final resolver = AppLocationResolver(
          cache: AppLocationGeocodeCache(store),
          geocoders: <AppLocationGeocoder>[localGeocoder],
          geocoder: externalGeocoder,
        );

        final result = await resolver.resolve(
          const AppLocationLookupInput.ibgeMunicipalityCode(
            ibgeMunicipalityCode: '1100015',
          ),
        );

        final outcome = result.getOrNull();
        expect(outcome, isA<AppLocationResolutionResolved>());
        final resolved = outcome;
        if (resolved is! AppLocationResolutionResolved) {
          fail('Expected resolved outcome.');
        }
        expect(
          resolved.location.source,
          AppLocationSource.staticBrazilMunicipalityCentroid,
        );
        expect(externalGeocoder.calls, 0);
        expect(store.values, isEmpty);
      },
    );

    test('writes geocoder result to persistent cache', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      final resolver = AppLocationResolver(
        cache: cache,
        geocoder: _FakeGeocoder(
          result: const AppLocationGeocoderResult.resolved(
            AppResolvedLocation(
              point: AppGeoPoint(latitude: -23.55, longitude: -46.63),
              precision: AppLocationPrecision.cep,
              source: AppLocationSource.geocodingProvider,
              cacheKey: 'ignored',
              label: 'Sao Paulo / SP',
              details: AppResolvedAddressDetails(
                city: 'Sao Paulo',
                uf: 'SP',
                countryCode: 'BR',
              ),
            ),
          ),
        ),
        now: () => DateTime.utc(2026, 5, 9),
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );
      final cached = await cache.readEntry('location_geocode_cep_01001000');

      expect(result.isSuccess(), isTrue);
      expect(cached?.isResolved, isTrue);
      expect(cached?.providerId, 'fake');
      expect(cached?.location?.details?.uf, 'SP');
    });

    test('serves negative cache hits without calling provider', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      final key = AppLocationLookupNormalizer.cacheKeyForStreetAddress(
        const AppPostalAddress(
          street: 'Rua das Flores',
          number: '123',
          city: 'Sinop',
          uf: 'MT',
        ),
      )!;
      await cache.writeNotFound(
        cacheKey: key,
        lookupType: AppLocationLookupType.streetAddress,
        providerId: 'fake',
        createdAt: DateTime.utc(2026, 5, 10),
      );
      final geocoder = _FakeGeocoder(
        result: const AppLocationGeocoderResult.notFound(),
      );
      final resolver = AppLocationResolver(
        cache: cache,
        geocoder: geocoder,
        now: () => DateTime.utc(2026, 5, 11),
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            street: 'Rua das Flores',
            number: '123',
            city: 'Sinop',
            uf: 'MT',
          ),
        ),
      );

      expect(result.isSuccess(), isTrue);
      expect(result.getOrNull(), isA<AppLocationResolutionNotFound>());
      expect(geocoder.calls, 0);
    });

    test('falls back between providers before succeeding', () async {
      final first = _FakeGeocoder(
        providerId: 'first',
        result: const AppLocationGeocoderResult.notFound(),
      );
      final second = _FakeGeocoder(
        providerId: 'second',
        result: const AppLocationGeocoderResult.resolved(
          AppResolvedLocation(
            point: AppGeoPoint(latitude: -23.55, longitude: -46.63),
            precision: AppLocationPrecision.exact,
            source: AppLocationSource.geocodingProvider,
            cacheKey: '',
          ),
        ),
      );
      final resolver = AppLocationResolver(
        cache: AppLocationGeocodeCache(_FakeCacheStore()),
        geocoders: <AppLocationGeocoder>[first, second],
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            street: 'Av Paulista',
            number: '1000',
            city: 'Sao Paulo',
            uf: 'SP',
          ),
        ),
      );

      final outcome = result.getOrNull();
      expect(outcome, isA<AppLocationResolutionResolved>());
      final resolved = outcome;
      if (resolved is! AppLocationResolutionResolved) {
        fail('Expected resolved outcome.');
      }
      expect(
        resolved.location.point.latitude,
        -23.55,
      );
      expect(first.calls, 1);
      expect(second.calls, 1);
    });

    test('does not persist negative cache after transient failure', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      final resolver = AppLocationResolver(
        cache: cache,
        geocoder: _FakeGeocoder(
          result: const AppLocationGeocoderResult.transientFailure(
            message: 'rate-limited',
            retryAfter: Duration(seconds: 30),
          ),
        ),
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            street: 'Rua das Flores',
            number: '123',
            city: 'Sinop',
            uf: 'MT',
          ),
        ),
      );
      final key = AppLocationLookupNormalizer.cacheKeyForStreetAddress(
        const AppPostalAddress(
          street: 'Rua das Flores',
          number: '123',
          city: 'Sinop',
          uf: 'MT',
        ),
      )!;

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull()?.isTransient, isTrue);
      expect(await cache.readEntry(key), isNull);
    });

    test('deduplicates concurrent identical lookups', () async {
      final geocoder = _FakeGeocoder(
        resultBuilder: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return const AppLocationGeocoderResult.resolved(
            AppResolvedLocation(
              point: AppGeoPoint(latitude: -23.55, longitude: -46.63),
              precision: AppLocationPrecision.exact,
              source: AppLocationSource.geocodingProvider,
              cacheKey: '',
            ),
          );
        },
      );
      final resolver = AppLocationResolver(
        cache: AppLocationGeocodeCache(_FakeCacheStore()),
        geocoder: geocoder,
      );
      const input = AppLocationLookupInput.streetAddress(
        postalAddress: AppPostalAddress(
          street: 'Av Paulista',
          number: '1000',
          city: 'Sao Paulo',
          uf: 'SP',
        ),
      );

      final results =
          await Future.wait<AppResult<AppLocationResolutionOutcome>>(
            <Future<AppResult<AppLocationResolutionOutcome>>>[
              resolver.resolve(input),
              resolver.resolve(input),
            ],
          );

      expect(results.every((result) => result.isSuccess()), isTrue);
      expect(geocoder.calls, 1);
    });

    test(
      'returns unsupported failure for street address without provider',
      () async {
        final resolver = AppLocationResolver(
          cache: AppLocationGeocodeCache(_FakeCacheStore()),
        );

        final result = await resolver.resolve(
          const AppLocationLookupInput.streetAddress(
            postalAddress: AppPostalAddress(
              street: 'Av Paulista',
              number: '1000',
              city: 'Sao Paulo',
              uf: 'SP',
            ),
          ),
        );

        expect(result.isError(), isTrue);
        expect(
          result.exceptionOrNull()?.displayMessage,
          'A geolocalizacao por endereco nao esta disponivel nesta plataforma.',
        );
      },
    );

    test('falls back to static Brazil UF centroid', () async {
      final cache = AppLocationGeocodeCache(_FakeCacheStore());
      final resolver = AppLocationResolver(
        cache: cache,
        now: () => DateTime.utc(2026, 5, 9),
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.uf(uf: 'MT'),
      );

      final outcome = result.getOrNull();
      expect(outcome, isA<AppLocationResolutionResolved>());
      final resolved = outcome;
      if (resolved is! AppLocationResolutionResolved) {
        fail('Expected resolved outcome.');
      }
      final location = resolved.location;
      expect(location.precision, AppLocationPrecision.stateCentroid);
      expect(location.source, AppLocationSource.staticBrazilStateCentroid);
      expect(location.details?.uf, 'MT');
    });

    test('emits safe observer events without raw address payloads', () async {
      final observer = _FakeObserver();
      final resolver = AppLocationResolver(
        cache: AppLocationGeocodeCache(_FakeCacheStore()),
        observer: observer,
        geocoder: _FakeGeocoder(
          result: const AppLocationGeocoderResult.notFound(),
        ),
      );

      await resolver.resolve(
        const AppLocationLookupInput.streetAddress(
          postalAddress: AppPostalAddress(
            street: 'Rua das Flores',
            number: '123',
            city: 'Sinop',
            uf: 'MT',
            cep: '78550005',
          ),
        ),
      );

      expect(observer.events, isNotEmpty);
      expect(
        observer.events.every(
          (event) => !event.context.values.any(
            (value) => value?.toString().contains('Rua das Flores') ?? false,
          ),
        ),
        isTrue,
      );
    });
  });
}

class _FakeCacheStore implements AppCacheStore {
  final values = <String, String>{};

  @override
  Future<void> clearAll() async {
    values.clear();
  }

  @override
  Future<String?> getString(String key) async {
    return values[key];
  }

  @override
  Future<void> putString({
    required String key,
    required String value,
  }) async {
    values[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    values.remove(key);
  }
}

class _FakeGeocoder implements AppLocationGeocoder {
  _FakeGeocoder({
    AppLocationGeocoderResult? result,
    this.providerId = 'fake',
    this.resultBuilder,
  }) : _result = result;

  final AppLocationGeocoderResult? _result;
  final Future<AppLocationGeocoderResult> Function(
    AppLocationLookupInput input,
  )?
  resultBuilder;
  int calls = 0;

  @override
  final String providerId;

  @override
  bool get isExternal => true;

  @override
  int get maxConcurrentRequests => 1;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    calls += 1;
    final builder = resultBuilder;
    if (builder != null) {
      return builder(input);
    }
    return _result ?? const AppLocationGeocoderResult.unsupported();
  }
}

class _FakeObserver extends AppLocationResolutionObserver {
  final List<({String event, Map<String, Object?> context})> events =
      <({String event, Map<String, Object?> context})>[];

  @override
  void onEvent({
    required String event,
    required Map<String, Object?> context,
  }) {
    events.add((event: event, context: context));
  }
}

String _municipalityCsv(List<String> fields) {
  return '${AppBrazilMunicipalityCentroidIndex.expectedHeader}\n'
      '${fields.join(';')}\n';
}
