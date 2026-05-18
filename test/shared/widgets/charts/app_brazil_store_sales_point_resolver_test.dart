import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_asset_geocoder.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_centroid_index.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_map_models.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBrazilStoreSalesPointResolver', () {
    test('uses provided geo point before IBGE lookup', () async {
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: AppLocationGeocodeCache(_FakeCacheStore()),
          geocoders: <AppLocationGeocoder>[
            _municipalityGeocoder(),
          ],
        ),
      );

      final point = await resolver.resolve(
        const AppBrazilStoreSalesPointSource(
          id: 'store-1',
          name: 'Loja manual',
          uf: 'mt',
          city: 'Sinop',
          latitude: -11.86,
          longitude: -55.50,
          ibgeMunicipalityCode: '1100015',
          salesAmount: 100,
          salesCount: 2,
        ),
      );

      expect(point?.uf, 'MT');
      expect(point?.city, 'Sinop');
      expect(point?.municipalityCode, '1100015');
      expect(
        point?.locationResolution,
        AppBrazilStoreSalesLocationResolution.providedGeoPoint,
      );
      expect(point?.latitude, -11.86);
      expect(point?.longitude, -55.50);
    });

    test('resolves IBGE lookup and fills city and UF from metadata', () async {
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: AppLocationGeocodeCache(_FakeCacheStore()),
          geocoders: <AppLocationGeocoder>[
            _municipalityGeocoder(),
          ],
        ),
      );

      final point = await resolver.resolve(
        const AppBrazilStoreSalesPointSource(
          id: 'store-2',
          name: 'Loja IBGE',
          ibgeMunicipalityCode: '1100015.0',
          salesAmount: 250,
          salesCount: 4,
        ),
      );

      expect(point?.uf, 'RO');
      expect(point?.city, "Alta Floresta D'Oeste");
      expect(point?.municipalityCode, '1100015');
      expect(
        point?.locationResolution,
        AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
      );
      expect(point?.latitude, -11.9283);
      expect(point?.longitude, -61.9953);
    });

    test('uses IBGE before cached CEP when both are available', () async {
      final cacheStore = _FakeCacheStore();
      final cache = AppLocationGeocodeCache(cacheStore);
      await cache.write(
        const AppResolvedLocation(
          point: AppGeoPoint(latitude: -23.5505, longitude: -46.6333),
          precision: AppLocationPrecision.cep,
          source: AppLocationSource.geocodingProvider,
          cacheKey: 'location_geocode_cep_01001000',
          details: AppResolvedAddressDetails(
            uf: 'SP',
            city: 'Sao Paulo',
            countryCode: 'BR',
          ),
        ),
      );
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: cache,
          geocoders: <AppLocationGeocoder>[
            _municipalityGeocoder(),
          ],
        ),
      );

      final point = await resolver.resolve(
        const AppBrazilStoreSalesPointSource(
          id: 'store-cep',
          name: 'Loja CEP',
          cep: '01001-000',
          ibgeMunicipalityCode: '1100015',
          salesAmount: 250,
          salesCount: 4,
        ),
      );

      expect(point?.uf, 'RO');
      expect(point?.city, "Alta Floresta D'Oeste");
      expect(point?.latitude, -11.9283);
      expect(point?.longitude, -61.9953);
      expect(point?.municipalityCode, '1100015');
      expect(
        point?.locationResolution,
        AppBrazilStoreSalesLocationResolution.ibgeMunicipalityCode,
      );
    });

    test('can fallback to capital when only UF is available', () async {
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: AppLocationGeocodeCache(_FakeCacheStore()),
          geocoders: <AppLocationGeocoder>[
            _municipalityGeocoder(),
          ],
        ),
      );

      final point = await resolver.resolve(
        const AppBrazilStoreSalesPointSource(
          id: 'store-3',
          name: 'Loja capital',
          uf: 'MT',
          preferCapitalFallback: true,
          salesAmount: 80,
          salesCount: 1,
        ),
      );

      expect(point?.uf, 'MT');
      expect(point?.city, 'Cuiaba');
      expect(
        point?.locationResolution,
        AppBrazilStoreSalesLocationResolution.capitalUf,
      );
      expect(point?.latitude, -15.601);
      expect(point?.longitude, -56.0974);
    });

    test('can disable UF fallback for branch-level positioning', () async {
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: AppLocationGeocodeCache(_FakeCacheStore()),
        ),
      );

      final point = await resolver.resolve(
        const AppBrazilStoreSalesPointSource(
          id: 'store-uf',
          name: 'Loja UF',
          uf: 'MT',
          allowUfFallback: false,
          salesAmount: 80,
          salesCount: 1,
        ),
      );

      expect(point, isNull);
    });

    test('returns null when no location key can be built', () async {
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: AppLocationGeocodeCache(_FakeCacheStore()),
        ),
      );

      final point = await resolver.resolve(
        const AppBrazilStoreSalesPointSource(
          id: 'store-4',
          name: 'Loja sem localizacao',
          salesAmount: 80,
          salesCount: 1,
        ),
      );

      expect(point, isNull);
    });

    test('memoizes repeated lookups in resolveAllWithDetails', () async {
      final geocoder = _CountingGeocoder();
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: AppLocationGeocodeCache(_FakeCacheStore()),
          geocoders: <AppLocationGeocoder>[geocoder],
        ),
      );

      final points = await resolver.resolveAllWithDetails(
        const <AppBrazilStoreSalesPointSource>[
          AppBrazilStoreSalesPointSource(
            id: 'store-a',
            name: 'Loja A',
            ibgeMunicipalityCode: '5103403',
            salesAmount: 10,
            salesCount: 1,
          ),
          AppBrazilStoreSalesPointSource(
            id: 'store-b',
            name: 'Loja B',
            ibgeMunicipalityCode: '5103403',
            salesAmount: 20,
            salesCount: 2,
          ),
        ],
      );

      expect(points.map((item) => item.point.id), <String>[
        'store-a',
        'store-b',
      ]);
      expect(points.map((item) => item.point.salesAmount), <double>[10, 20]);
      expect(geocoder.lookupCount, 1);
    });

    test('limits concurrent lookups and preserves source order', () async {
      final geocoder = _DelayedCountingGeocoder();
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: AppLocationGeocodeCache(_FakeCacheStore()),
          geocoders: <AppLocationGeocoder>[geocoder],
        ),
      );

      final points = await resolver.resolveAllWithDetails(
        const <AppBrazilStoreSalesPointSource>[
          AppBrazilStoreSalesPointSource(
            id: 'store-1',
            name: 'Loja 1',
            ibgeMunicipalityCode: '5103401',
            salesAmount: 10,
            salesCount: 1,
          ),
          AppBrazilStoreSalesPointSource(
            id: 'store-2',
            name: 'Loja 2',
            ibgeMunicipalityCode: '5103402',
            salesAmount: 20,
            salesCount: 2,
          ),
          AppBrazilStoreSalesPointSource(
            id: 'store-3',
            name: 'Loja 3',
            ibgeMunicipalityCode: '5103403',
            salesAmount: 30,
            salesCount: 3,
          ),
          AppBrazilStoreSalesPointSource(
            id: 'store-4',
            name: 'Loja 4',
            ibgeMunicipalityCode: '5103404',
            salesAmount: 40,
            salesCount: 4,
          ),
        ],
        maxConcurrent: 2,
      );

      expect(points.map((item) => item.point.id), <String>[
        'store-1',
        'store-2',
        'store-3',
        'store-4',
      ]);
      expect(geocoder.maxActiveLookups, greaterThan(1));
      expect(geocoder.maxActiveLookups, lessThanOrEqualTo(2));
    });
  });
}

AppBrazilMunicipalityAssetGeocoder _municipalityGeocoder() {
  return AppBrazilMunicipalityAssetGeocoder(
    indexLoader: () async => AppBrazilMunicipalityCentroidIndex.parse(
      _municipalityCsv(<List<String>>[
        <String>[
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
        ],
        <String>[
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
        ],
      ]),
    ),
  );
}

String _municipalityCsv(List<List<String>> rows) {
  return '${AppBrazilMunicipalityCentroidIndex.expectedHeader}\n'
      '${rows.map((row) => row.join(';')).join('\n')}\n';
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

class _CountingGeocoder implements AppLocationGeocoder {
  int lookupCount = 0;

  @override
  String get providerId => 'counting';

  @override
  bool get isExternal => false;

  @override
  int get maxConcurrentRequests => 1;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    lookupCount += 1;
    if (input.ibgeMunicipalityCode != '5103403') {
      return const AppLocationGeocoderResult.notFound();
    }

    return const AppLocationGeocoderResult.resolved(
      AppResolvedLocation(
        point: AppGeoPoint(latitude: -15.601, longitude: -56.0974),
        precision: AppLocationPrecision.city,
        source: AppLocationSource.staticBrazilMunicipalityCentroid,
        cacheKey: 'location_geocode_ibge_5103403',
        details: AppResolvedAddressDetails(
          uf: 'MT',
          city: 'Cuiaba',
          countryCode: 'BR',
        ),
      ),
    );
  }
}

class _DelayedCountingGeocoder implements AppLocationGeocoder {
  int _activeLookups = 0;
  int maxActiveLookups = 0;

  @override
  String get providerId => 'delayed-counting';

  @override
  bool get isExternal => false;

  @override
  int get maxConcurrentRequests => 1;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    _activeLookups += 1;
    if (_activeLookups > maxActiveLookups) {
      maxActiveLookups = _activeLookups;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
    _activeLookups -= 1;

    return AppLocationGeocoderResult.resolved(
      AppResolvedLocation(
        point: const AppGeoPoint(latitude: -15.601, longitude: -56.0974),
        precision: AppLocationPrecision.city,
        source: AppLocationSource.staticBrazilMunicipalityCentroid,
        cacheKey: 'location_geocode_ibge_${input.ibgeMunicipalityCode}',
        details: const AppResolvedAddressDetails(
          uf: 'MT',
          city: 'Cuiaba',
          countryCode: 'BR',
        ),
      ),
    );
  }
}
