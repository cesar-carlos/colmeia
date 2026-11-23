@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/data/queries/parcela_produto_vendido_detalhe_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository_v2.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ResumoParcelaFormaPagamentoRepositoryV2 (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'real SQL evaluates mixed-method change without double allocation',
        () async {
          if (missingE2eRepositoryKeys().isNotEmpty) {
            markTestSkipped('E2E credentials unavailable');
            return;
          }
          final result = await runE2eAppResult(
            () => getIt<AgentQueriesRepository>().executeSql(
              AgentSqlExecuteRequest(
                agentId: AppEnvironment.e2eAgentId,
                clientToken: AppEnvironment.e2eClientToken,
                requestingUserId: 'user-1',
                bridgeTimeoutMs: 15000,
                totalTimeoutMs: 20000,
                skipTransportCache: true,
                useRelay: true,
                relayMode: AgentSqlRelayMode.streaming,
                executeOptions: const AgentSqlExecuteOptions(
                  executionMode: AgentSqlExecutionMode.preserve,
                  maxRows: 32,
                  sqlTimeoutMs: 10000,
                ),
                sql:
                    """
              SELECT det.Cenario, ${ParcelaProdutoVendidoDetalheSql.trocoExpression} AS Troco
              FROM (
                SELECT 1 AS Cenario, 100.0 AS ValorParcela, 150.0 AS ValorTotalParcelas,
                  100.0 AS ValorTotalParcelasRateioTroco, 20.0 AS ValorTotalTrocoVenda, 'DH' AS TipoForma
                UNION ALL SELECT 2, 50.0, 150.0, 100.0, 20.0, 'CC'
                UNION ALL SELECT 3, 10.0, 100.0, 10.0, 20.0, 'DH'
                UNION ALL SELECT 4, 90.0, 100.0, 10.0, 20.0, 'CC'
                UNION ALL SELECT 5, 50.0, 100.0, 100.0, 0.0, 'PIX'
                UNION ALL SELECT 6, 50.0, 100.0, 100.0, 20.0, 'PIX'
              ) det
              ORDER BY det.Cenario
            """,
              ),
            ),
          );
          final failure = result.exceptionOrNull();
          if (failure != null &&
              isAcceptableE2eAgentSqlRepositoryFailure(failure)) {
            markTestSkipped(
              'Bridge did not execute the numeric fixture: ${failure.message}',
            );
            return;
          }
          expect(
            result.isSuccess(),
            isTrue,
            reason:
                '${result.exceptionOrNull()?.runtimeType}: ${result.exceptionOrNull()?.message}',
          );
          final rows = result.getOrNull()!.rows;
          expect(rows, hasLength(6));
          const expected = [20.0, 0.0, 2.0, 18.0, 0.0, 10.0];
          for (var i = 0; i < expected.length; i++) {
            final row = {
              for (final entry in rows[i].entries)
                entry.key.toLowerCase(): entry.value,
            };
            expect(
              double.parse(row['troco'].toString()),
              closeTo(expected[i], 0.000001),
            );
          }
        },
      );

      test(
        'load executes the real V2 resumo query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_repository_v2_e2e: missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository = getIt<ResumoParcelaFormaPagamentoRepositoryV2>();
          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = periodEnd.subtract(const Duration(days: 14));

          final result = await runE2eAppResult(
            () => repository.load(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: ResumoParcelaFormaPagamentoFilterV2(
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
                expect(row.codFormaPagamento.trim(), isNotEmpty);
                expect(row.descricaoFormaPagamento.trim(), isNotEmpty);
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
                    'Repository e2e should return rows, invalid_policy / '
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
