import 'dart:io';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_asset_geocoder.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_centroid_index.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_lookup_normalizer.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
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
          city: ' Sao José do Rio Preto ',
          uf: ' sp ',
        ),
        'location_geocode_city_uf_SAO_JOSE_DO_RIO_PRETO_SP',
      );
      expect(
        AppLocationLookupNormalizer.cacheKeyForUf(' mt '),
        'location_geocode_uf_MT',
      );
      expect(
        AppLocationLookupNormalizer.cacheKeyForCapitalUf(' mt '),
        'location_geocode_capital_uf_MT',
      );
      expect(
        AppLocationLookupNormalizer.cacheKeyForIbgeMunicipality('1100015'),
        'location_geocode_ibge_1100015',
      );
    });

    test('rejects incomplete lookup keys', () {
      expect(AppLocationLookupNormalizer.cacheKeyForCep('123'), isNull);
      expect(
        AppLocationLookupNormalizer.cacheKeyForCityUf(
          city: '',
          uf: 'MT',
        ),
        isNull,
      );
      expect(AppLocationLookupNormalizer.cacheKeyForUf('MTO'), isNull);
      expect(
        AppLocationLookupNormalizer.cacheKeyForIbgeMunicipality('110001'),
        isNull,
      );
      expect(AppLocationLookupNormalizer.cacheKeyForCapitalUf('MTO'), isNull);
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
      expect(centroid?.ufCode, 11);
      expect(centroid?.uf, 'RO');
      expect(centroid?.stateName, 'Rondonia');
      expect(centroid?.region, 'Norte');
      expect(centroid?.isCapital, isFalse);
      expect(centroid?.longitude, -61.9953);
      expect(centroid?.latitude, -11.9283);
      expect(centroid?.siafiId, '0033');
      expect(centroid?.ddd, '69');
      expect(centroid?.timezone, 'America/Porto_Velho');
    });

    test('rejects invalid header', () {
      expect(
        () => AppBrazilMunicipalityCentroidIndex.parse(
          'CODIGO;NOME;LONGITUDE;LATITUDE\n',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('looks up capital by UF', () {
      final index = AppBrazilMunicipalityCentroidIndex.parse(
        _municipalityCsv(<String>[
          '5103403',
          'Cuiaba',
          '51',
          'MT',
          'Mato Grosso',
          'Centro-Oeste',
          '1',
          '-15.601',
          '-56.0974',
          '9067',
          '65',
          'America/Porto_Velho',
        ]),
      );

      final capital = index.lookupCapitalByUf('mt');

      expect(capital?.ibgeCode, '5103403');
      expect(capital?.isCapital, isTrue);
    });

    test('loads full municipality asset', () {
      final file = File(AppBrazilMunicipalityCentroidIndex.assetPath);
      final index = AppBrazilMunicipalityCentroidIndex.parse(
        file.readAsStringSync(),
      );
      final centroid = index.lookupByIbgeCode('1100015');
      final newestMunicipality = index.lookupByIbgeCode('5101837');
      final missing = index.lookupByIbgeCode('9999999');

      expect(AppBrazilMunicipalityCentroidIndex.sourceLicense, 'MIT');
      expect(
        AppBrazilMunicipalityCentroidIndex.sourceUrl,
        contains('kelvins/municipios-brasileiros'),
      );
      expect(index.length, 5571);
      expect(
        file.readAsLinesSync().where((line) => line.isNotEmpty),
        hasLength(5572),
      );
      expect(index.capitalCount, 27);
      expect(index.ufs, hasLength(27));
      expect(
        index.regions,
        containsAll(<String>[
          'Norte',
          'Nordeste',
          'Centro-Oeste',
          'Sudeste',
          'Sul',
        ]),
      );
      expect(centroid?.name, "Alta Floresta D'Oeste");
      expect(newestMunicipality?.name, startsWith('Boa Esperan'));
      expect(newestMunicipality?.uf, 'MT');
      expect(newestMunicipality?.region, 'Centro-Oeste');
      expect(index.values.every((centroid) => centroid.point.isValid), isTrue);
      expect(index.values.every((centroid) => centroid.uf.length == 2), isTrue);
      expect(missing, isNull);
    });

    test('looks up by city and explicit UF', () {
      final index = AppBrazilMunicipalityCentroidIndex.parse(
        _municipalityCsv(<String>[
          '3550308',
          'Sao Paulo',
          '35',
          'SP',
          'Sao Paulo',
          'Sudeste',
          '1',
          '-23.5329',
          '-46.6395',
          '7107',
          '11',
          'America/Sao_Paulo',
        ]),
      );

      final centroid = index.lookupByCityUf(city: 'Sao Paulo', uf: 'SP');

      expect(centroid?.ibgeCode, '3550308');
      expect(centroid?.isCapital, isTrue);
    });
  });

  group('AppLocationGeocodeCache', () {
    test('round-trips resolved locations as JSON', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      const location = AppResolvedLocation(
        point: AppGeoPoint(latitude: -11.86, longitude: -55.50),
        precision: AppLocationPrecision.city,
        source: AppLocationSource.geocodingProvider,
        cacheKey: 'location_geocode_city_uf_SINOP_MT',
        label: 'Sinop / MT',
        metadata: <String, Object?>{
          'ibgeCode': '5107909',
          'uf': 'MT',
        },
      );

      await cache.write(location);
      final cached = await cache.read(location.cacheKey);

      expect(cached?.point.latitude, -11.86);
      expect(cached?.point.longitude, -55.50);
      expect(cached?.precision, AppLocationPrecision.city);
      expect(cached?.source, AppLocationSource.geocodingProvider);
      expect(cached?.label, 'Sinop / MT');
      expect(cached?.metadata['ibgeCode'], '5107909');
      expect(cached?.metadata['uf'], 'MT');
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

      expect(result?.source, AppLocationSource.provided);
      expect(result?.precision, AppLocationPrecision.exact);
      expect(result?.point.latitude, -15.6);
      expect(store.values, isEmpty);
    });

    test('returns cached CEP location before calling geocoder', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      final key = AppLocationLookupNormalizer.cacheKeyForCep('01001-000')!;
      await cache.write(
        AppResolvedLocation(
          point: const AppGeoPoint(latitude: -11.86, longitude: -55.50),
          precision: AppLocationPrecision.city,
          source: AppLocationSource.geocodingProvider,
          cacheKey: key,
          resolvedAt: DateTime.utc(2026),
        ),
      );
      final geocoder = _FakeGeocoder(
        result: AppResolvedLocation(
          point: const AppGeoPoint(latitude: -1, longitude: -1),
          precision: AppLocationPrecision.city,
          source: AppLocationSource.geocodingProvider,
          cacheKey: key,
          resolvedAt: DateTime.utc(2026),
        ),
      );
      final resolver = AppLocationResolver(cache: cache, geocoder: geocoder);

      final result = await resolver.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );

      expect(result?.source, AppLocationSource.cache);
      expect(result?.point.latitude, -11.86);
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
          result: const AppResolvedLocation(
            point: AppGeoPoint(latitude: -1, longitude: -1),
            precision: AppLocationPrecision.city,
            source: AppLocationSource.geocodingProvider,
            cacheKey: 'ignored',
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

        expect(
          result?.source,
          AppLocationSource.staticBrazilMunicipalityCentroid,
        );
        expect(result?.precision, AppLocationPrecision.city);
        expect(result?.point.longitude, -61.9953);
        expect(result?.point.latitude, -11.9283);
        expect(result?.label, "Alta Floresta D'Oeste / RO");
        expect(result?.metadata['ibgeCode'], '1100015');
        expect(result?.metadata['uf'], 'RO');
        expect(result?.metadata['region'], 'Norte');
        expect(externalGeocoder.calls, 0);
        expect(store.values, isEmpty);
      },
    );

    test('resolves capital fallback by UF without persistent cache', () async {
      final store = _FakeCacheStore();
      final localGeocoder = AppBrazilMunicipalityAssetGeocoder(
        indexLoader: () async => AppBrazilMunicipalityCentroidIndex.parse(
          _municipalityCsv(<String>[
            '5103403',
            'Cuiaba',
            '51',
            'MT',
            'Mato Grosso',
            'Centro-Oeste',
            '1',
            '-15.601',
            '-56.0974',
            '9067',
            '65',
            'America/Porto_Velho',
          ]),
        ),
      );
      final resolver = AppLocationResolver(
        cache: AppLocationGeocodeCache(store),
        geocoders: <AppLocationGeocoder>[localGeocoder],
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.capitalUf(uf: 'MT'),
      );

      expect(
        result?.source,
        AppLocationSource.staticBrazilMunicipalityCentroid,
      );
      expect(result?.label, 'Cuiaba / MT');
      expect(result?.metadata['isCapital'], isTrue);
      expect(store.values, isEmpty);
    });

    test('writes geocoder result to cache', () async {
      final store = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(store);
      final resolver = AppLocationResolver(
        cache: cache,
        geocoder: _FakeGeocoder(
          result: const AppResolvedLocation(
            point: AppGeoPoint(latitude: -23.55, longitude: -46.63),
            precision: AppLocationPrecision.cep,
            source: AppLocationSource.geocodingProvider,
            cacheKey: 'ignored',
            label: 'Sao Paulo / SP',
          ),
        ),
        now: () => DateTime.utc(2026, 5, 9),
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.cep(cep: '01001-000'),
      );
      final cached = await cache.read('location_geocode_cep_01001000');

      expect(result?.cacheKey, 'location_geocode_cep_01001000');
      expect(result?.resolvedAt, DateTime.utc(2026, 5, 9));
      expect(cached?.point.latitude, -23.55);
    });

    test('falls back to static Brazil UF centroid', () async {
      final cache = AppLocationGeocodeCache(_FakeCacheStore());
      final resolver = AppLocationResolver(
        cache: cache,
        now: () => DateTime.utc(2026, 5, 9),
      );

      final result = await resolver.resolve(
        const AppLocationLookupInput.uf(uf: 'MT'),
      );
      final cached = await cache.read('location_geocode_uf_MT');

      expect(result?.precision, AppLocationPrecision.stateCentroid);
      expect(result?.source, AppLocationSource.staticBrazilStateCentroid);
      expect(result?.label, 'Mato Grosso');
      expect(result?.point.isValid, isTrue);
      expect(cached, isNull);
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
  _FakeGeocoder({this.result});

  final AppResolvedLocation? result;
  int calls = 0;

  @override
  String get providerId => 'fake';

  @override
  Future<AppResolvedLocation?> resolve(AppLocationLookupInput input) async {
    calls += 1;
    return result;
  }
}

String _municipalityCsv(List<String> fields) {
  return '${AppBrazilMunicipalityCentroidIndex.expectedHeader}\n'
      '${fields.join(';')}\n';
}
