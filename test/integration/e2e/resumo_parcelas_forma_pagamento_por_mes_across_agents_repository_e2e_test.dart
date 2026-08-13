@Tags(['e2e'])
library;

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Across-agents smoke for parcel × payment method by month.
///
/// Kept in its own file because stacking this query after sibling reports
/// hangs agent SQL (~95s RelayRequestTimeout) and poisons later tests.
///
/// Uses the same rolling 14-day sale window as the unary repository e2e
/// probe for this query so local runs stay aligned with that test file.
void main() {
  group(
    'LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'mergeAll loads payment-method-by-month resumo for a recent sale window',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // ignore: avoid_print -- E2E skip hints for missing credentials (same as sibling agent-query e2e).
            print(
              'SKIP resumo_parcelas_forma_pagamento_por_mes_across_agents_repository_e2e_test: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = periodEnd.subtract(const Duration(days: 14));
          final filter = ResumoParcelasFormaPagamentoPorMesFilter(
            dataVendaInicio: periodStart,
            dataVendaFim: periodEnd,
          );

          final useCase =
              getIt<
                LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase
              >();
          final result = await runE2eAppResult(
            () => useCase(
              userId: 'user-1',
              filter: filter,
              bridgeTimeoutMs: 300000,
            ),
          );

          result.fold(
            (report) {
              expect(
                report.mergedRows.length,
                lessThanOrEqualTo(
                  AgentQueriesBoundedResultMaxRows
                      .resumoParcelasFormaPagamentoPorMes,
                ),
              );
              for (final row in report.mergedRows) {
                expect(row.codEmpresa, greaterThan(0));
                expect(row.codFilial, greaterThanOrEqualTo(0));
                expect(row.nomeUsuario, isNotEmpty);
                expect(row.anoMesDataVenda, isNotEmpty);
                expect(row.codFormaPagamento, isNotEmpty);
                expect(row.descricaoFormaPagamento, isNotEmpty);
                expect(row.qtdVendas, greaterThanOrEqualTo(0));
                expect(row.valorParcela, isNonNegative);
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
                    'Across-agents e2e should return rows, invalid_policy / '
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
