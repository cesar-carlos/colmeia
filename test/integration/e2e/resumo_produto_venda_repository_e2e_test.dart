import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row_number_ordering.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Direct repository smoke for the paged product sales summary query.
void main() {
  group(
    'ResumoProdutoVendaRepository (e2e)',
    () {
      test(
        'loadPage page 1 executes the real resumo query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_produto_venda_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<ResumoProdutoVendaRepository>();
          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = periodEnd.subtract(const Duration(days: 14));

          final result = await repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ResumoProdutoVendaFilter(
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
            ),
          );

          result.fold(
            (page) {
              checkPageInvariants(
                page.items,
                page.totalCount,
                ResumoProdutoVendaFilter.defaultPageSize,
              );
              if (page.totalCount > 0) {
                expect(
                  page.items,
                  isNotEmpty,
                  reason:
                      'Page 1 should return items when totalCount > 0 '
                      '(unless only TotalCount row — then mapping would be empty)',
                );
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
        'loadPage page 2 shares totalCount when more than one page exists',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_produto_venda_repository_e2e (page 2): missing '
              '${missingKeys.join(', ')}.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<ResumoProdutoVendaRepository>();
          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = periodEnd.subtract(const Duration(days: 14));

          const smallPageSize = 10;
          final first = await repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ResumoProdutoVendaFilter(
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
              pageSize: smallPageSize,
            ),
          );

          if (first.isError()) {
            final failure = first.exceptionOrNull()!;
            expect(failure, isNot(isA<SessionFailure>()));
            expect(
              isAcceptableE2eAgentSqlRepositoryFailure(failure),
              isTrue,
            );
            return;
          }

          final page1 = first.getOrThrow();
          checkPageInvariants(page1.items, page1.totalCount, smallPageSize);
          if (page1.totalCount <= smallPageSize) {
            return;
          }

          final totalCount = page1.totalCount;
          final second = await repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ResumoProdutoVendaFilter(
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
              page: 2,
              pageSize: smallPageSize,
            ),
          );

          second.fold(
            (page2) {
              expect(page2.totalCount, totalCount);
              expect(page2.items.length, lessThanOrEqualTo(smallPageSize));
              checkPageInvariants(page2.items, page2.totalCount, smallPageSize);

              if (page1.items.isNotEmpty && page2.items.isNotEmpty) {
                String key(ResumoProdutoVendaRow r) =>
                    '${r.codEmpresa}-${r.codFilial}-${r.codProduto}';
                final keys1 = page1.items.map(key).toSet();
                final overlap =
                    page2.items.where((r) => keys1.contains(key(r))).toList();
                expect(
                  overlap,
                  isEmpty,
                  reason:
                      'Page 2 rows should not repeat (CodEmpresa, CodFilial, '
                      'CodProduto) keys from page 1',
                );
              }
            },
            (failure) {
              expect(failure, isNot(isA<SessionFailure>()));
              expect(
                isAcceptableE2eAgentSqlRepositoryFailure(failure),
                isTrue,
              );
            },
          );
        },
      );

      test(
        'loadPage home-style top 15 uses metricGlobal ranking',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP resumo_produto_venda_repository_e2e (home top 15): missing '
              '${missingKeys.join(', ')}.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<ResumoProdutoVendaRepository>();
          final today = DateTime.now();
          final periodEnd = DateTime(today.year, today.month, today.day);
          final periodStart = periodEnd.subtract(const Duration(days: 14));

          const homePageSize = 15;
          final result = await repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: ResumoProdutoVendaFilter(
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
              pageSize: homePageSize,
              rowNumberOrdering: ResumoProdutoVendaRowNumberOrdering.metricGlobal,
            ),
          );

          result.fold(
            (page) {
              checkPageInvariants(
                page.items,
                page.totalCount,
                homePageSize,
              );
              if (page.items.length >= 2) {
                for (var i = 0; i < page.items.length - 1; i++) {
                  expect(
                    page.items[i].qtdVendas,
                    greaterThanOrEqualTo(page.items[i + 1].qtdVendas),
                    reason:
                        'metricGlobal + qtdVendas DESC should not increase '
                        'down the page',
                  );
                }
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

void checkPageInvariants(
  List<ResumoProdutoVendaRow> items,
  int totalCount,
  int pageSize,
) {
  expect(totalCount, greaterThanOrEqualTo(0));
  expect(items.length, lessThanOrEqualTo(pageSize));
  for (final row in items) {
    expect(row.codEmpresa, greaterThan(0));
    expect(row.codFilial, greaterThanOrEqualTo(0));
    expect(row.codProduto, greaterThan(0));
    expect(row.nomeProduto, isNotEmpty);
    expect(row.qtdVendas, greaterThanOrEqualTo(0));
    expect(row.qtdItensVendido, greaterThanOrEqualTo(0));
    expect(row.valorTotalCustoMedio, greaterThanOrEqualTo(0));
    expect(row.custoReposicao, greaterThanOrEqualTo(0));
    expect(row.pontoEquilibrio, greaterThanOrEqualTo(0));
    expect(row.valorTotalItem, greaterThanOrEqualTo(0));
  }
}
