@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Direct repository smoke for the period product profitability query.
///
/// Groups by CodEmpresa/CodFilial for the requested date range — one row
/// per branch. Same bridge path as the monthly lucratividade variant.
void main() {
  group(
    'ResumoProdutoVendaLucratividadeRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'loadAll executes the real lucratividade query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_produto_venda_lucratividade_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository = getIt<ResumoProdutoVendaLucratividadeRepository>();
          final periodStart = DateTime(2026);
          final periodEnd = DateTime(2026, 3, 31);

          final result = await runE2eAppResult(
            () => repository.loadAll(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: ResumoProdutoVendaLucratividadeFilter(
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
                expect(row.qtdItensVendido, isNonNegative);
                expect(row.valorTotalItem, isNonNegative);
                expect(row.custoReposicao, isNonNegative);
                expect(row.percentualCustoSobreVenda, isNonNegative);
                expect(row.margemLucroBrutoPercent, isNonNegative);
                expect(row.markupSobreCustoPercent, isNonNegative);
                expect(row.filialLabel, matches(RegExp(r'^\d+-\d+$')));
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

      test(
        'use case executes the same lucratividade query (overview stack path)',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP load_resumo_produto_venda_lucratividade use_case e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final useCase = getIt<LoadResumoProdutoVendaLucratividadeUseCase>();
          final periodStart = DateTime(2026);
          final periodEnd = DateTime(2026, 3, 31);

          final result = await runE2eAppResult(
            () => useCase(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: ResumoProdutoVendaLucratividadeFilter(
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
                expect(row.qtdItensVendido, isNonNegative);
                expect(row.valorTotalItem, isNonNegative);
                expect(row.custoReposicao, isNonNegative);
                expect(row.percentualCustoSobreVenda, isNonNegative);
                expect(row.margemLucroBrutoPercent, isNonNegative);
                expect(row.markupSobreCustoPercent, isNonNegative);
                expect(row.filialLabel, matches(RegExp(r'^\d+-\d+$')));
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
                    'Use-case e2e should return rows, invalid_policy / '
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
