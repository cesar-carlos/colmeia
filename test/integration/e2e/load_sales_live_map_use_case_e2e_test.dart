@Tags(['e2e'])
library;

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/data/sales_live_map_catalog_disk_cache.dart';
import 'package:colmeia/features/sales/data/sales_live_map_point_resolver_adapter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_asset_geocoder.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'LoadSalesLiveMapUseCase (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test('combines branch catalog and sales summary for the map', () async {
        final missingKeys = missingE2eRepositoryKeys();
        if (missingKeys.isNotEmpty) {
          // E2E skip hint must be visible in CLI output.
          // ignore: avoid_print
          print(
            'SKIP load_sales_live_map_use_case_e2e: missing '
            '${missingKeys.join(', ')}. '
            'Set them in assets/env/local.env, process env, or --dart-define.',
          );
          return;
        }

        SharedPreferences.setMockInitialValues(<String, Object>{});
        final catalogDiskCache = SalesLiveMapCatalogDiskCache(
          await SharedPreferences.getInstance(),
        );

        final locationResolver = AppLocationResolver(
          cache: AppLocationGeocodeCache(_E2eMemoryCacheStore()),
          geocoders: const <AppLocationGeocoder>[
            AppBrazilMunicipalityAssetGeocoder(),
          ],
        );
        final useCase = LoadSalesLiveMapUseCase(
          getIt<AgentQueryTargetResolver>(),
          catalogDiskCache,
          getIt<
            LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
          >(),
          getIt<LoadCadastroFilialAcrossAgentsUseCase>(),
          SalesLiveMapPointResolverAdapter(
            delegate: AppBrazilStoreSalesPointResolver(
              locationResolver: locationResolver,
            ),
          ),
        );

        final result = await useCase(
          userId: 'e2e-user',
          filter: const SalesLiveMapFilter(
            periodMode: SalesLiveMapPeriodMode.lastSevenDays,
          ),
        );

        expect(result.totalBranchCount, greaterThanOrEqualTo(0));
        expect(
          result.mappedBranchCount,
          lessThanOrEqualTo(result.totalBranchCount),
        );
        expect(result.catalogBranchCount, result.totalBranchCount);
        expect(
          result.zeroedBranchCount,
          result.noSalesBranchCount + result.salesUnavailableBranchCount,
        );
        for (final point in result.points) {
          expect(point.companyCode, isNotNull);
          expect(point.branchCode, isNotNull);
          expect(point.agentName, isNotNull);
          if (point.salesDataUnavailable) {
            expect(point.salesAmount, 0);
            expect(point.salesCount, 0);
          }
        }
        if (result.hasPartialIssue) {
          // E2E: surface partialIssueActiveKeys in CLI when diagnosing hub/geo data.
          // ignore: avoid_print
          print(
            'E2E load_sales_live_map partialIssueActiveKeys: '
            '${result.partialIssueActiveKeys}',
          );
        }
      });
    },
    tags: <String>['e2e'],
  );
}

class _E2eMemoryCacheStore implements AppCacheStore {
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
