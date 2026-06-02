import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/agent_queries/application/usecases/resolve_cadastro_filial_location_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/maps/resolve_postal_address_location_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResolveCadastroFilialLocationUseCase', () {
    test('converts filial address and resolves location', () async {
      final useCase = ResolveCadastroFilialLocationUseCase(
        ResolvePostalAddressLocationUseCase(
          AppLocationResolver(
            cache: AppLocationGeocodeCache(_MemoryCacheStore()),
            geocoder: _FakeGeocoder(
              result: const AppLocationGeocoderResult.resolved(
                AppResolvedLocation(
                  point: AppGeoPoint(
                    latitude: -15.601,
                    longitude: -56.0974,
                  ),
                  precision: AppLocationPrecision.exact,
                  source: AppLocationSource.geocodingProvider,
                  cacheKey: '',
                  details: AppResolvedAddressDetails(
                    city: 'Cuiaba',
                    uf: 'MT',
                    countryCode: 'BR',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final result = await useCase(
        const CadastroFilialRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeFilial: 'Matriz',
          endereco: 'Av do CPA',
          numeroEndereco: '1000',
          bairro: 'Centro Politico',
          cep: '78049900',
          nomeMunicipio: 'Cuiaba',
          ufMunicipio: 'MT',
        ),
      );

      expect(result.isSuccess(), isTrue);
      expect(result.getOrNull()?.found, isTrue);
      expect(result.getOrNull()?.latitude, -15.601);
      expect(result.getOrNull()?.city, 'Cuiaba');
      expect(result.getOrNull()?.uf, 'MT');
    });

    test('returns notFound for filial without usable address', () async {
      final geocoder = _FakeGeocoder(
        result: const AppLocationGeocoderResult.notFound(),
      );
      final useCase = ResolveCadastroFilialLocationUseCase(
        ResolvePostalAddressLocationUseCase(
          AppLocationResolver(
            cache: AppLocationGeocodeCache(_MemoryCacheStore()),
            geocoder: geocoder,
          ),
        ),
      );

      final result = await useCase(
        const CadastroFilialRow(
          codEmpresa: 1,
          codFilial: 1,
          nomeFilial: 'Sem endereco',
        ),
      );

      expect(result.isSuccess(), isTrue);
      expect(result.getOrNull()?.found, isFalse);
      expect(geocoder.calls, 0);
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
