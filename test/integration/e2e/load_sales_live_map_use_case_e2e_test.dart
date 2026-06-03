@Tags(['e2e'])
@Timeout(Duration(minutes: 7))
library;

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/di/injector_sales.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/shared/maps/app_brazil_municipality_asset_geocoder.dart';
import 'package:colmeia/shared/maps/app_location_geocode_cache.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_counting_agent_queries_repository.dart';
import 'support/e2e_dependency_bootstrap.dart';
import 'support/e2e_in_memory_app_cache_store.dart';
import 'support/e2e_sales_live_map_merged_batch_assertions.dart';

const String _e2eLoadSalesLiveMapScopeName = 'e2e_load_sales_live_map';

void main() {
  group(
    'LoadSalesLiveMapUseCase (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      late E2eCountingAgentQueriesRepository countingRepository;

      setUp(() async {
        if (missingE2eRepositoryKeys().isNotEmpty) {
          return;
        }
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final sharedPreferences = await SharedPreferences.getInstance();
        getIt
          ..pushNewScope(scopeName: _e2eLoadSalesLiveMapScopeName)
          ..registerSingleton<SharedPreferences>(sharedPreferences)
          ..registerSingleton<AppCacheStore>(E2eInMemoryAppCacheStore())
          ..registerLazySingleton<AppLocationResolver>(
            () => AppLocationResolver(
              cache: AppLocationGeocodeCache(getIt<AppCacheStore>()),
              geocoders: const <AppLocationGeocoder>[
                AppBrazilMunicipalityAssetGeocoder(),
              ],
            ),
          );
        countingRepository = E2eCountingAgentQueriesRepository(
          getIt<AgentQueriesRepository>(),
        );
        getIt.registerSingleton<AgentQueriesRepository>(countingRepository);
        registerInjectorSales(getIt);
      });

      tearDown(() async {
        if (getIt.currentScopeName != _e2eLoadSalesLiveMapScopeName) {
          return;
        }
        await getIt.popScope();
      });

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

        final useCase = getIt<LoadSalesLiveMapUseCase>();
        final filter = SalesLiveMapFilter(
          periodMode: SalesLiveMapPeriodMode.lastSevenDays,
          selectedAgentIds: AppEnvironment.agentSqlSalesLiveMapMergeSqlBatchesPerTarget
              ? <String>{AppEnvironment.e2eAgentId}
              : null,
        );

        final result = await runE2eAppResultWithHubRetry(
          () async {
            final loadResult = await useCase(
              userId: 'e2e-user',
              filter: filter,
            );
            if (loadResult.loadFailed) {
              final failure = loadResult.loadFailure;
              if (failure != null) {
                return Failure<SalesLiveMapLoadResult, AppFailure>(failure);
              }
            }
            return Success<SalesLiveMapLoadResult, AppFailure>(loadResult);
          },
          actionLabel: 'load_sales_live_map_use_case',
        );

        final mapResult = result.getOrNull();
        if (mapResult == null) {
          expectSalesLiveMapAgentSqlE2eFailure(result.exceptionOrNull()!);
          return;
        }

        _expectSalesLiveMapUseCaseSmoke(mapResult);

        if (AppEnvironment.agentSqlSalesLiveMapMergeSqlBatchesPerTarget) {
          expectSalesLiveMapMergedBatchSql(countingRepository);
          final metricEvent = getIt<SalesLiveMapRefreshMetrics>().latest;
          expect(metricEvent, isNotNull);
          expect(metricEvent!.catalogSalesBatchMerged, isTrue);
          expect(metricEvent.mergeWaveSize, AppEnvironment.salesLiveMapMergeWaveSize);
        } else {
          // E2E skip hint when merge flag is off; stdout is intentional.
          // ignore: avoid_print
          print(
            'load_sales_live_map_use_case_e2e: merged-batch SQL assertions skipped '
            '(set AGENT_SQL_SALES_LIVE_MAP_MERGE_SQL_BATCHES_PER_TARGET=true).',
          );
        }

        if (mapResult.hasPartialIssue) {
          // E2E: surface partialIssueActiveKeys in CLI when diagnosing hub/geo data.
          // ignore: avoid_print
          print(
            'E2E load_sales_live_map partialIssueActiveKeys: '
            '${mapResult.partialIssueActiveKeys}',
          );
        }
      });
    },
    tags: <String>['e2e'],
  );
}

void _expectSalesLiveMapUseCaseSmoke(
  SalesLiveMapLoadResult result,
) {
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
}
