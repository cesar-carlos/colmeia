@Tags(['e2e'])
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_mensal_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Direct repository smoke for the monthly product profitability query.
///
/// Groups by CodEmpresa/CodFilial/Ano/Mes — one row per branch per month.
void main() {
  group(
    'ResumoProdutoVendaLucratividadeMensalRepository (e2e)',
    () {
      test(
        'loadAll executes the real lucratividade mensal query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_produto_venda_lucratividade_mensal_repository_e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository =
              getIt<ResumoProdutoVendaLucratividadeMensalRepository>();
          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = DateTime(today.year - 1, today.month);

          final result = await repository.loadAll(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ResumoProdutoVendaLucratividadeMensalFilter(
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
            ),
          );

          result.fold(
            (rows) {
              for (final row in rows) {
                expect(row.codEmpresa, greaterThan(0));
                expect(row.codFilial, greaterThanOrEqualTo(0));
                expect(row.ano, greaterThan(1900));
                expect(row.mes, inInclusiveRange(1, 12));
                expect(row.anoMes, matches(RegExp(r'^\d{4}/\d{2}$')));
                expect(row.qtdVendas, greaterThanOrEqualTo(0));
                expect(row.qtdItensVendido, isNonNegative);
                expect(row.valorTotalItem, isNonNegative);
                expect(row.custoReposicao, isNonNegative);
                expect(row.percentualCustoSobreVenda, isNonNegative);
                expect(row.margemLucroBrutoPercent, isNonNegative);
                expect(row.markupSobreCustoPercent, isNonNegative);
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
