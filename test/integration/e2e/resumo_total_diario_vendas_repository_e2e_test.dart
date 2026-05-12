@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ResumoTotalDiarioVendasRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'load executes the real resumo query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Console hint when the full e2e credential set is absent.
            // ignore: avoid_print
            print(
              'SKIP resumo_total_diario_vendas_repository_e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository = getIt<ResumoTotalDiarioVendasRepository>();
          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = periodEnd.subtract(const Duration(days: 14));

          final result = await runE2eAppResult(
            () => repository.load(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: ResumoTotalDiarioVendasFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
              ),
            ),
          );

          result.fold(
            (rows) {
              for (final row in rows) {
                expect(row.codEmpresa, greaterThan(0));
                expect(row.codFilial, greaterThanOrEqualTo(0));
                expect(row.qtdVendas, greaterThanOrEqualTo(0));
                expect(row.valorTotalDiarioVenda, isNonNegative);
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
                    'Repository e2e should return rows, invalid_policy / '
                    'missing_permission RPC, or transient bridge HTTP 5xx.',
              );
            },
          );
        },
      );

      test('load accepts a single-day calendar range', () async {
        final missingKeys = missingE2eRepositoryKeys();
        if (missingKeys.isNotEmpty) {
          // E2E skip hint; `print` is intentional for local diagnostics.
          // ignore: avoid_print
          print(
            'SKIP resumo_total_diario_vendas_single_day_e2e: '
            'missing ${missingKeys.join(', ')}. '
            'Set them in assets/env/local.env, process env, or --dart-define.',
          );
          return;
        }

        final repository = getIt<ResumoTotalDiarioVendasRepository>();
        final today = DateTime.now();
        final day = DateTime(today.year, today.month, today.day);

        final result = await runE2eAppResult(
          () => repository.load(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ResumoTotalDiarioVendasFilter(
              dataVendaInicio: day,
              dataVendaFim: day,
            ),
          ),
        );

        result.fold(
          (rows) {
            for (final row in rows) {
              expect(row.dataVenda, DateTime(day.year, day.month, day.day));
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.valorTotalDiarioVenda, isNonNegative);
            }
          },
          (failure) {
            expect(
              failure,
              isNot(isA<SessionFailure>()),
              reason:
                  'Unexpected HTTP 401 after client login '
                  'â€” check E2E_* values.',
            );
            expect(
              isAcceptableE2eAgentSqlRepositoryFailure(failure),
              isTrue,
              reason:
                  'Single-day repository e2e should return rows, '
                  'invalid_policy / missing_permission RPC, or transient '
                  'bridge HTTP 5xx.',
            );
          },
        );
      });
    },
    tags: <String>['e2e'],
  );
}
