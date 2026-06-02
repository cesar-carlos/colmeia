import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/sales/data/sales_live_map_point_resolver_adapter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesLiveMapPointResolverAdapter', () {
    late SalesLiveMapPointResolverAdapter adapter;

    setUp(() {
      final resolver = AppBrazilStoreSalesPointResolver(
        locationResolver: AppLocationResolver(
          cache: AppLocationGeocodeCache(_MemoryCacheStore()),
          geocoders: <AppLocationGeocoder>[
            _SalesLiveMapAdapterTestGeocoder(),
          ],
        ),
      );
      adapter = SalesLiveMapPointResolverAdapter(delegate: resolver);
    });

    test(
      'preserves payload, subtitle and sales status on successful resolve',
      () async {
        const source = SalesLiveMapPointSource(
          id: 'store-geo',
          name: 'Filial Geo',
          uf: 'mt',
          city: 'Cuiaba',
          latitude: -15.6014,
          longitude: -56.0979,
          salesAmount: 0,
          salesCount: 0,
          fantasyName: 'Casa do Mel',
          branchName: 'Filial Centro',
          companyCode: 1,
          branchCode: 2,
          agentName: 'Agente A',
          salesDataUnavailable: true,
          salesDataStatusLabel: 'Vendas indisponiveis',
          subtitle: 'Agente A - Empresa 1 - Filial 2',
          payload: 'aggregate',
        );

        final point = await adapter.resolve(source);
        final detailed = await adapter.resolveWithDetails(source);

        expect(point, isNotNull);
        expect(
          point!.locationResolution,
          SalesLiveMapLocationResolution.providedGeoPoint,
        );
        expect(point.fantasyName, 'Casa do Mel');
        expect(point.branchName, 'Filial Centro');
        expect(point.companyCode, 1);
        expect(point.branchCode, 2);
        expect(point.agentName, 'Agente A');
        expect(point.salesDataUnavailable, isTrue);
        expect(point.salesDataStatusLabel, 'Vendas indisponiveis');
        expect(point.subtitle, 'Agente A - Empresa 1 - Filial 2');
        expect(point.payload, 'aggregate');
        expect(detailed, isNotNull);
        expect(detailed!.point.id, point.id);
        expect(detailed.point.locationResolution, point.locationResolution);
        expect(detailed.point.payload, point.payload);
      },
    );

    test(
      'returns null or empty collections when no location can be resolved',
      () async {
        const source = SalesLiveMapPointSource(
          id: 'store-missing',
          name: 'Filial sem localizacao',
          salesAmount: 10,
          salesCount: 1,
        );

        final single = await adapter.resolve(source);
        final many = await adapter.resolveAll(const <SalesLiveMapPointSource>[
          source,
        ]);
        final manyWithDetails = await adapter.resolveAllWithDetails(
          const <SalesLiveMapPointSource>[source],
        );

        expect(single, isNull);
        expect(many, isEmpty);
        expect(manyWithDetails, isEmpty);
      },
    );

    test(
      'maps every supported location resolution through the shared resolver',
      () async {
        final resolved = await adapter.resolveAllWithDetails(
          const <SalesLiveMapPointSource>[
            SalesLiveMapPointSource(
              id: 'provided',
              name: 'Provided',
              uf: 'MT',
              city: 'Cuiaba',
              latitude: -15.6014,
              longitude: -56.0979,
              salesAmount: 10,
              salesCount: 1,
            ),
            SalesLiveMapPointSource(
              id: 'ibge',
              name: 'IBGE',
              ibgeMunicipalityCode: '5103403',
              salesAmount: 20,
              salesCount: 2,
            ),
            SalesLiveMapPointSource(
              id: 'cep',
              name: 'CEP',
              cep: '78000-000',
              salesAmount: 30,
              salesCount: 3,
            ),
            SalesLiveMapPointSource(
              id: 'city-uf',
              name: 'City UF',
              city: 'Goiania',
              uf: 'GO',
              salesAmount: 40,
              salesCount: 4,
            ),
            SalesLiveMapPointSource(
              id: 'capital',
              name: 'Capital',
              uf: 'MT',
              preferCapitalFallback: true,
              salesAmount: 50,
              salesCount: 5,
            ),
            SalesLiveMapPointSource(
              id: 'uf',
              name: 'UF',
              uf: 'SP',
              salesAmount: 60,
              salesCount: 6,
            ),
          ],
        );

        expect(
          resolved.map((item) => item.point.locationResolution),
          <SalesLiveMapLocationResolution?>[
            SalesLiveMapLocationResolution.providedGeoPoint,
            SalesLiveMapLocationResolution.ibgeMunicipalityCode,
            SalesLiveMapLocationResolution.cep,
            SalesLiveMapLocationResolution.cityUf,
            SalesLiveMapLocationResolution.capitalUf,
            SalesLiveMapLocationResolution.stateUf,
          ],
        );
        expect(resolved.map((item) => item.point.id), <String>[
          'provided',
          'ibge',
          'cep',
          'city-uf',
          'capital',
          'uf',
        ]);
      },
    );
  });
}

class _SalesLiveMapAdapterTestGeocoder implements AppLocationGeocoder {
  @override
  String get providerId => 'sales-live-map-adapter-test';

  @override
  bool get isExternal => false;

  @override
  int get maxConcurrentRequests => 1;

  @override
  Future<AppLocationGeocoderResult> resolve(
    AppLocationLookupInput input,
  ) async {
    switch (input.type) {
      case AppLocationLookupType.ibgeMunicipalityCode:
        if (input.ibgeMunicipalityCode == '5103403') {
          return AppLocationGeocoderResult.resolved(
            _resolvedLocation(
              latitude: -15.6014,
              longitude: -56.0979,
              precision: AppLocationPrecision.city,
              source: AppLocationSource.staticBrazilMunicipalityCentroid,
              uf: 'MT',
              city: 'Cuiaba',
            ),
          );
        }
      case AppLocationLookupType.cep:
        if (input.cep == '78000-000' || input.cep == '78000000') {
          return AppLocationGeocoderResult.resolved(
            _resolvedLocation(
              latitude: -15.5989,
              longitude: -56.0949,
              precision: AppLocationPrecision.cep,
              source: AppLocationSource.geocodingProvider,
              uf: 'MT',
              city: 'Cuiaba',
              cep: '78000-000',
            ),
          );
        }
      case AppLocationLookupType.cityUf:
        if (input.city == 'Goiania' && input.uf == 'GO') {
          return AppLocationGeocoderResult.resolved(
            _resolvedLocation(
              latitude: -16.6869,
              longitude: -49.2648,
              precision: AppLocationPrecision.city,
              source: AppLocationSource.geocodingProvider,
              uf: 'GO',
              city: 'Goiania',
            ),
          );
        }
      case AppLocationLookupType.capitalUf:
        if (input.uf == 'MT') {
          return AppLocationGeocoderResult.resolved(
            _resolvedLocation(
              latitude: -15.601,
              longitude: -56.0974,
              precision: AppLocationPrecision.city,
              source: AppLocationSource.staticBrazilMunicipalityCentroid,
              uf: 'MT',
              city: 'Cuiaba',
            ),
          );
        }
      case AppLocationLookupType.uf:
        if (input.uf == 'SP') {
          return AppLocationGeocoderResult.resolved(
            _resolvedLocation(
              latitude: -22,
              longitude: -48,
              precision: AppLocationPrecision.stateCentroid,
              source: AppLocationSource.staticBrazilStateCentroid,
              uf: 'SP',
              city: 'Sao Paulo',
            ),
          );
        }
      case AppLocationLookupType.geoPoint ||
          AppLocationLookupType.streetAddress:
        break;
    }
    return const AppLocationGeocoderResult.notFound();
  }

  AppResolvedLocation _resolvedLocation({
    required double latitude,
    required double longitude,
    required AppLocationPrecision precision,
    required AppLocationSource source,
    required String uf,
    required String city,
    String? cep,
  }) {
    return AppResolvedLocation(
      point: AppGeoPoint(latitude: latitude, longitude: longitude),
      precision: precision,
      source: source,
      cacheKey: '$uf-$city-$precision',
      details: AppResolvedAddressDetails(
        uf: uf,
        city: city,
        cep: cep,
        countryCode: 'BR',
      ),
    );
  }
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

  @override
  Future<void> removeKeysWithPrefix(String prefix) async {
    _values.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> removeKeysWhere({
    required String prefix,
    required bool Function(String key) predicate,
  }) async {
    _values.removeWhere(
      (key, _) => key.startsWith(prefix) && predicate(key),
    );
  }
}
