@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_produto_rank_lucro_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_produto_rank_lucro_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ProdutoVendidoProdutoRankLucroRepository (e2e)',
    () {
      test(
        'loadAll executes the real rank query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Intentional stdout for local troubleshooting when E2E env is missing.
            // ignore: avoid_print
            print(
              'SKIP produto_vendido_produto_rank_lucro_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<ProdutoVendidoProdutoRankLucroRepository>();
          final periodStart = DateTime(2026);
          final periodEnd = DateTime(2026, 3, 31);

          final result = await runE2eAppResult(
            () => repository.loadAll(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: ProdutoVendidoProdutoRankLucroFilter(
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
                expect(row.codProduto, greaterThan(0));
                expect(row.nomeProduto, isNotEmpty);
                expect(row.qtdItensVendido, isNonNegative);
                expect(row.valorTotal, isNonNegative);
                expect(row.custoTotal, isNonNegative);
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
        'use case executes the same query (stack path)',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Intentional stdout for local troubleshooting when E2E env is missing.
            // ignore: avoid_print
            print(
              'SKIP load_produto_vendido_produto_rank_lucro use_case e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final useCase = getIt<LoadProdutoVendidoProdutoRankLucroUseCase>();
          final periodStart = DateTime(2026);
          final periodEnd = DateTime(2026, 3, 31);

          final result = await runE2eAppResult(
            () => useCase(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: ProdutoVendidoProdutoRankLucroFilter(
                dataVendaInicio: periodStart,
                dataVendaFim: periodEnd,
                sortBy: ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
              ),
            ),
          );

          result.fold(
            (rows) {
              for (final row in rows) {
                expect(row.codProduto, greaterThan(0));
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
