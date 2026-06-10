@Tags(['e2e'])
@Timeout(Duration(minutes: 7))
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/sales/application/sales_live_map_catalog_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_loader_impl.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_counting_agent_queries_repository.dart';
import 'support/e2e_dependency_bootstrap.dart';
import 'support/e2e_sales_live_map_merged_batch_assertions.dart';

void main() {
  group(
    'SalesLiveMapBatchLoader (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'runs merged catalog + sales through one sql.executeBatch per agent',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP sales_live_map_batch_loader_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }
          if (!AppEnvironment.agentSqlSalesLiveMapMergeSqlBatchesPerTarget) {
            // E2E skip hint when merge flag is off; stdout is intentional.
            // ignore: avoid_print
            print(
              'SKIP sales_live_map_batch_loader_e2e: set '
              '--dart-define=AGENT_SQL_SALES_LIVE_MAP_MERGE_SQL_BATCHES_PER_TARGET=true '
              '(or env) to assert merged catalog + sales batches.',
            );
            return;
          }

          final countingRepository = E2eCountingAgentQueriesRepository(
            getIt<AgentQueriesRepository>(),
          );
          final loader = SalesLiveMapBatchLoaderImpl(
            planBuilder: const AgentQueryPlanBuilder(),
            agentQueriesRepository: countingRepository,
            targetWaveConcurrency: 1,
          );
          final mapFilter = SalesLiveMapFilter(
            periodMode: SalesLiveMapPeriodMode.lastSevenDays,
            selectedAgentIds: <String>{AppEnvironment.e2eAgentId},
          );
          final catalogScope = SalesLiveMapCatalogScope.fullAgent(
            agentIds: <String>{AppEnvironment.e2eAgentId},
          );
          final catalogFilter = catalogScope.toCatalogFilter();
          final salesFilter = mapFilter.toAgentQueryFilter(
            codEmpresa: SalesLiveMapPolicies.primaryCompanyCode,
            codFilial: SalesLiveMapPolicies.primaryBranchCode,
          );

          final resolutionResult = await getIt<AgentQueryTargetResolver>()
              .resolve(
                userId: 'user-1',
                selectedAgentIds: mapFilter.selectedAgentIds,
              );
          final resolution = resolutionResult.getOrNull();
          if (resolution == null) {
            final failure = resolutionResult.exceptionOrNull()!;
            expectSalesLiveMapAgentSqlE2eFailure(failure);
            return;
          }

          final result = await runE2eAppResultWithHubRetry(
            () => loader.load(
              userId: 'user-1',
              catalogFilter: catalogFilter,
              salesFilter: salesFilter,
              preResolvedResolution: resolution,
              targetWaveConcurrency: 1,
            ),
            actionLabel: 'sales_live_map_batch_loader',
          );

          result.fold(
            (success) {
              expectSalesLiveMapMergedBatchSql(countingRepository);
              expect(success.catalogPage.report.participants, isNotEmpty);
              expect(success.salesReport.participants, isNotEmpty);
              final catalogParticipant = success.catalogPage.report.participants
                  .singleWhere(
                    (participant) =>
                        participant.agentId == AppEnvironment.e2eAgentId,
                    orElse: () => success.catalogPage.report.participants.first,
                  );
              final salesParticipant = success.salesReport.participants
                  .singleWhere(
                    (participant) =>
                        participant.agentId == AppEnvironment.e2eAgentId,
                    orElse: () => success.salesReport.participants.first,
                  );
              if (catalogParticipant.failure != null) {
                expectSalesLiveMapAgentSqlE2eFailure(
                  catalogParticipant.failure!,
                );
                return;
              }
              if (salesParticipant.failure != null) {
                expectSalesLiveMapAgentSqlE2eFailure(
                  salesParticipant.failure!,
                );
                return;
              }
              for (final row in catalogParticipant.rows) {
                expect(row.codEmpresa, greaterThan(0));
                expect(row.codFilial, greaterThan(0));
              }
              for (final row in salesParticipant.rows) {
                expect(row.qtdVendas, greaterThanOrEqualTo(0));
                expect(row.totalVenda, isNonNegative);
              }
            },
            expectSalesLiveMapAgentSqlE2eFailure,
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
