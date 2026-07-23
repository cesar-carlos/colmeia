@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_total_vendas_municipio_filial_periodo_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_periodo_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_counting_agent_queries_repository.dart';
import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ResumoTotalVendasMunicipioFilialPeriodoRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'DI registers the caching decorator for the period repository',
        () {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // ignore: avoid_print, reason: E2E skip reason must be visible in CLI output.
            print(
              'SKIP resumo_total_vendas_municipio_filial_periodo_di_e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }
          expect(
            getIt<ResumoTotalVendasMunicipioFilialPeriodoRepository>(),
            isA<CachingResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl>(),
          );
        },
      );

      test(
        'load executes the period query and reuses facts on a second load',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // ignore: avoid_print, reason: E2E skip reason must be visible in CLI output.
            print(
              'SKIP resumo_total_vendas_municipio_filial_periodo_repository_e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final counting = E2eCountingAgentQueriesRepository(
            getIt<AgentQueriesRepository>(),
          );
          final repository =
              CachingResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl(
                delegate: ResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl(
                  counting,
                ),
                factsStore: getIt<AgentQueryFactsStore>(),
                agentQueriesRepository: counting,
              );
          // Two closed days: cold cache loads one SQL per missing day bucket,
          // so longer windows dominate the suite without extra coverage.
          final periodStart = DateTime(2026, 7, 10);
          final periodEnd = DateTime(2026, 7, 11);
          final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          );
          const userId = 'user-1';
          final agentId = AppEnvironment.e2eAgentId;
          final clientToken = AppEnvironment.e2eClientToken;

          final first = await runE2eAppResult(
            () => repository.load(
              userId: userId,
              agentId: agentId,
              clientToken: clientToken,
              filter: filter,
            ),
          );

          if (first.isError()) {
            final failure = first.exceptionOrNull()!;
            expect(
              failure,
              isNot(isA<SessionFailure>()),
              reason:
                  'Unexpected HTTP 401 after client login '
                  '-- check E2E_* values.',
            );
            expect(
              isAcceptableE2eAgentSqlRepositoryFailure(failure),
              isTrue,
              reason:
                  'Repository e2e should return rows, invalid_policy / '
                  'missing_permission RPC, transient transport, queue '
                  'saturation, or transient bridge HTTP 5xx.',
            );
            return;
          }

          final loadedRows = first.getOrThrow();
          // E2E diagnostic; stdout is intentional for local triage.
          // ignore: avoid_print
          print(
            'E2E municipio periodo: sourceRowCount=${loadedRows.sourceRowCount} '
            'rows=${loadedRows.rows.length} period=$periodStart..$periodEnd',
          );
          expect(loadedRows.sourceRowCount, greaterThanOrEqualTo(0));
          expect(
            loadedRows.rows.length,
            lessThanOrEqualTo(
              AgentQueriesBoundedResultMaxRows
                  .resumoTotalVendasMunicipioFilialPeriodo,
            ),
          );
          for (final row in loadedRows.rows) {
            expect(row.codEmpresa, greaterThan(0));
            expect(row.codFilial, greaterThanOrEqualTo(0));
            expect(row.nomeFilial, isNotEmpty);
            final codMunicipio = row.codMunicipioFilial;
            if (codMunicipio != null) {
              expect(codMunicipio, greaterThan(0));
            }
            final municipio = row.nomeMunicipioFilial;
            if (municipio != null) {
              expect(municipio, isNotEmpty);
            }
            final uf = row.ufMunicipioFilial;
            if (uf != null) {
              expect(uf, isNotEmpty);
            }
            expect(row.qtdVendas, greaterThanOrEqualTo(0));
            expect(row.totalVenda, isNonNegative);
            final fantasia = row.nomeFantasiaFilial;
            if (fantasia != null) {
              expect(fantasia, isNotEmpty);
            }
            final cep = row.cepFilial;
            if (cep != null) {
              expect(cep, isNotEmpty);
            }
            final ibge = row.codigoIbgeMunicipioFilial;
            if (ibge != null) {
              expect(ibge, matches(RegExp(r'^\d{7}$')));
            }
          }

          expect(
            counting.executeSqlCallCount + counting.executeSqlBatchCallCount,
            greaterThan(0),
            reason: 'First load should hit the bridge for closed buckets.',
          );
          final sqlCallsAfterFirst =
              counting.executeSqlCallCount + counting.executeSqlBatchCallCount;

          final second = await runE2eAppResult(
            () => repository.load(
              userId: userId,
              agentId: agentId,
              clientToken: clientToken,
              filter: filter,
            ),
          );

          second.fold(
            (_) {
              expect(
                counting.executeSqlCallCount +
                    counting.executeSqlBatchCallCount,
                sqlCallsAfterFirst,
                reason:
                    'Second load should read closed buckets from the facts '
                    'store without additional sql.execute calls.',
              );
            },
            (failure) {
              expect(
                failure,
                isNot(isA<SessionFailure>()),
                reason: 'Unexpected HTTP 401 on cache re-read.',
              );
              expect(
                isAcceptableE2eAgentSqlRepositoryFailure(failure),
                isTrue,
                reason:
                    'Cache re-read e2e accepts the same environmental failures '
                    'as the primary repository probe.',
              );
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
