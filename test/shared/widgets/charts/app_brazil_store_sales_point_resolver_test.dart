import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_asset_geocoder.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_centroid_index.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
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
          ibgeMunicipalityCode: '1100015',
          salesAmount: 250,
          salesCount: 4,
        ),
      );

      expect(point?.uf, 'RO');
      expect(point?.city, "Alta Floresta D'Oeste");
      expect(point?.latitude, -11.9283);
      expect(point?.longitude, -61.9953);
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
      expect(point?.latitude, -15.601);
      expect(point?.longitude, -56.0974);
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
