@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Exercises [ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository.loadAllOptions]
/// (one `sql.executeBatch` per agent) against the live bridge.
void main() {
  group(
    'ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      late DateTime periodStart;
      late DateTime periodEnd;

      setUp(() {
        final today = DateTime.now();
        periodEnd = DateTime(today.year, today.month, today.day);
        periodStart = periodEnd.subtract(const Duration(days: 90));
      });

      test(
        'loadAllOptions returns merged vendedor, bairro and municipio',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            /// E2E: explain skip when repository keys are not configured.
            // ignore: avoid_print
            print(
              'SKIP resumo_vendas_diarias_filter_options_across_agents_e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository =
              getIt<
                ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
              >();

          final result = await runE2eAppResultWithHubRetry(
            () => repository.loadAllOptions(
              userId: 'user-1',
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
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
    },
    tags: <String>['e2e'],
  );
}
