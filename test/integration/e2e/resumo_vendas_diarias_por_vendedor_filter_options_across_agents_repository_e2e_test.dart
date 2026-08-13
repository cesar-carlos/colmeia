@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_across_agents_report.dart';
import 'support/e2e_dependency_bootstrap.dart';

/// Exercises [ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository]
/// and the dedicated option use cases against the live bridge.
void main() {
  group(
    'ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'loadAllOptions returns merged vendedor, bairro and municipio',
        () async {
          if (skipE2eWhenMissingRepositoryKeys(
            'resumo_vendas_diarias_filter_options_across_agents_e2e',
          )) {
            return;
          }

          final period = e2eKnownSalesPeriod();
          final repository =
              getIt<
                ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
              >();

          final result = await runE2eAppResultWithHubRetry(
            () => repository.loadAllOptions(
              userId: 'user-1',
              dataVendaInicio: period.start,
              dataVendaFim: period.end,
              selectedAgentIds: {AppEnvironment.e2eAgentId},
            ),
            actionLabel: 'resumo_vendas_diarias_opts_batch_across',
          );

          result.fold(
            (bundle) {
              for (final opt in bundle.vendedorOptions) {
                expect(opt.codVendedor, greaterThan(0));
                expect(opt.nomeVendedor, isNotEmpty);
              }
              for (final opt in bundle.bairroOptions) {
                expect(opt.value, isNotEmpty);
              }
              for (final opt in bundle.municipioOptions) {
                expect(opt.value, isNotEmpty);
              }
            },
            (failure) {
              expect(
                failure,
                isNot(isA<SessionFailure>()),
                reason:
                    'Unexpected HTTP 401 after client login '
                    '— check E2E_* values.',
              );
              expect(
                isAcceptableE2eAgentSqlRepositoryFailure(failure),
                isTrue,
                reason:
                    'Repository e2e should return options, invalid_policy / '
                    'missing_permission RPC, or transient bridge HTTP 5xx.',
              );
            },
          );
        },
      );

      test('load vendedor options through the across-agent use case', () async {
        if (skipE2eWhenMissingRepositoryKeys(
          'agent_query_across_vendedor_options',
        )) {
          return;
        }

        final period = e2eKnownSalesPeriod();
        final useCase =
            getIt<
              LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase
            >();
        expectE2eAcrossAgentsList(
          await runE2eAcrossAgentsResult(
            () => useCase(
              userId: e2eAcrossAgentsUserId,
              dataVendaInicio: period.start,
              dataVendaFim: period.end,
              limit: 5,
              bridgeTimeoutMs: e2eAcrossAgentsBridgeTimeoutMs,
            ),
          ),
          (option) {
            expect(option.codVendedor, greaterThan(0));
            expect(option.nomeVendedor, isNotEmpty);
          },
        );
      });

      test('load bairro options through the across-agent use case', () async {
        if (skipE2eWhenMissingRepositoryKeys(
          'agent_query_across_bairro_options',
        )) {
          return;
        }

        final period = e2eKnownSalesPeriod();
        final useCase =
            getIt<
              LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase
            >();
        expectE2eAcrossAgentsList(
          await runE2eAcrossAgentsResult(
            () => useCase(
              userId: e2eAcrossAgentsUserId,
              dataVendaInicio: period.start,
              dataVendaFim: period.end,
              limit: 5,
              bridgeTimeoutMs: e2eAcrossAgentsBridgeTimeoutMs,
            ),
          ),
          (option) => expect(option.value, isNotEmpty),
        );
      });

      test('load municipio options through the across-agent use case', () async {
        if (skipE2eWhenMissingRepositoryKeys(
          'agent_query_across_municipio_options',
        )) {
          return;
        }

        final period = e2eKnownSalesPeriod();
        final useCase =
            getIt<
              LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase
            >();
        expectE2eAcrossAgentsList(
          await runE2eAcrossAgentsResult(
            () => useCase(
              userId: e2eAcrossAgentsUserId,
              dataVendaInicio: period.start,
              dataVendaFim: period.end,
              limit: 5,
              bridgeTimeoutMs: e2eAcrossAgentsBridgeTimeoutMs,
            ),
          ),
          (option) => expect(option.value, isNotEmpty),
        );
      });
    },
    tags: <String>['e2e'],
  );
}
