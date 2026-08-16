@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_agent_queries_test_helpers.dart';
import 'support/e2e_name_filter_helpers.dart';

void main() {
  group(
    'MargemProdutoRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'loadPage page 1 executes the real product-margin catalog query',
        () async {
          if (shouldSkipE2eRepositoryTest('margem_produto_repository_e2e')) {
            return;
          }

          final repository = getIt<MargemProdutoRepository>();
          final result = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const MargemProdutoFilter(),
            ),
          );

          result.fold(
            (page) {
              checkPageInvariants(
                page.items,
                page.totalCount,
                MargemProdutoFilter.defaultPageSize,
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
              expectAcceptableAgentQueriesE2eFailure(
                failure,
                failureScope: 'Repository e2e',
              );
            },
          );
        },
      );

      test(
        'loadPage page 2 shares totalCount when more than one page exists',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'margem_produto_repository_e2e (page 2)',
          )) {
            return;
          }

          final repository = getIt<MargemProdutoRepository>();
          const smallPageSize = 10;
          const filterPage1 = MargemProdutoFilter(
            pageSize: smallPageSize,
          );

          final first = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: filterPage1,
            ),
          );

          if (first.isError()) {
            expectAcceptableAgentQueriesE2eFailure(
              first.exceptionOrNull()!,
              failureScope: 'Repository e2e',
            );
            return;
          }

          final page1 = first.getOrThrow();
          checkPageInvariants(page1.items, page1.totalCount, smallPageSize);
          if (page1.totalCount <= smallPageSize) {
            return;
          }

          final totalCount = page1.totalCount;
          final second = await runE2eAppResultWithHubRetry(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const MargemProdutoFilter(
                page: 2,
                pageSize: smallPageSize,
              ),
            ),
            actionLabel: 'margem_produto_loadPage_page2',
          );

          second.fold(
            (page2) {
              expect(page2.totalCount, totalCount);
              expect(page2.items.length, lessThanOrEqualTo(smallPageSize));
              checkPageInvariants(
                page2.items,
                page2.totalCount,
                smallPageSize,
              );

              if (page1.items.isNotEmpty && page2.items.isNotEmpty) {
                final keys1 = page1.items.map((row) => row.codProduto).toSet();
                final overlap = page2.items
                    .where((row) => keys1.contains(row.codProduto))
                    .toList();
                expect(
                  overlap,
                  isEmpty,
                  reason: 'Page 2 rows should not repeat CodProduto keys from page 1',
                );
              }
            },
            (failure) {
              expectAcceptableAgentQueriesE2eFailure(
                failure,
                failureScope: 'Repository e2e',
              );
            },
          );
        },
      );

      test(
        'loadPage default nomeProduto ASC does not decrease down the page',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'margem_produto_repository_e2e (sort name ASC)',
          )) {
            return;
          }

          final repository = getIt<MargemProdutoRepository>();
          final result = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const MargemProdutoFilter(),
            ),
          );

          result.fold(
            (page) {
              checkPageInvariants(
                page.items,
                page.totalCount,
                MargemProdutoFilter.defaultPageSize,
              );
              if (page.items.length >= 2) {
                expectNomeProdutoAscending(page.items);
              }
            },
            (failure) {
              expectAcceptableAgentQueriesE2eFailure(
                failure,
                failureScope: 'Repository e2e',
              );
            },
          );
        },
      );

      test(
        'loadPage page 2 continues NomeProduto order without overlap',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'margem_produto_repository_e2e (name page 2)',
          )) {
            return;
          }

          final repository = getIt<MargemProdutoRepository>();
          const smallPageSize = 10;
          const filterPage1 = MargemProdutoFilter(
            pageSize: smallPageSize,
          );

          final first = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: filterPage1,
            ),
          );

          if (first.isError()) {
            expectAcceptableAgentQueriesE2eFailure(
              first.exceptionOrNull()!,
              failureScope: 'Repository e2e',
            );
            return;
          }

          final page1 = first.getOrThrow();
          checkPageInvariants(page1.items, page1.totalCount, smallPageSize);
          expectNomeProdutoAscending(page1.items);
          if (page1.totalCount <= smallPageSize) {
            return;
          }

          final second = await runE2eAppResultWithHubRetry(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const MargemProdutoFilter(
                page: 2,
                pageSize: smallPageSize,
              ),
            ),
            actionLabel: 'margem_produto_loadPage_name_page2',
          );

          second.fold(
            (page2) {
              expect(page2.totalCount, page1.totalCount);
              checkPageInvariants(
                page2.items,
                page2.totalCount,
                smallPageSize,
              );
              expectNomeProdutoAscending(page2.items);
              if (page1.items.isNotEmpty && page2.items.isNotEmpty) {
                final keys1 = page1.items.map((row) => row.codProduto).toSet();
                expect(
                  page2.items.where((row) => keys1.contains(row.codProduto)),
                  isEmpty,
                  reason: 'Page 2 rows should not repeat CodProduto keys from page 1',
                );
                final last = page1.items.last;
                final firstRow = page2.items.first;
                final nameOrder = foldNomeProdutoForOrder(
                  last.nomeProduto,
                ).compareTo(foldNomeProdutoForOrder(firstRow.nomeProduto));
                expect(
                  nameOrder,
                  lessThanOrEqualTo(0),
                  reason: 'Page 2 should continue NomeProduto ASC after page 1',
                );
                if (nameOrder == 0) {
                  expect(
                    last.codProduto,
                    lessThan(firstRow.codProduto),
                    reason: 'equal NomeProduto should keep CodProduto ASC across pages',
                  );
                }
              }
            },
            (failure) {
              expectAcceptableAgentQueriesE2eFailure(
                failure,
                failureScope: 'Repository e2e',
              );
            },
          );
        },
      );

      test(
        'loadPage contains search matches NomeProduto and does not raise total',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'margem_produto_repository_e2e (name contains)',
          )) {
            return;
          }

          final repository = getIt<MargemProdutoRepository>();
          const baselineFilter = MargemProdutoFilter();
          final baseline = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: baselineFilter,
            ),
          );

          if (baseline.isError()) {
            expectAcceptableAgentQueriesE2eFailure(
              baseline.exceptionOrNull()!,
              failureScope: 'Repository e2e',
            );
            return;
          }

          final page1 = baseline.getOrThrow();
          checkPageInvariants(
            page1.items,
            page1.totalCount,
            MargemProdutoFilter.defaultPageSize,
          );
          if (page1.items.isEmpty) {
            return;
          }

          final filterToken = buildContainsToken(page1.items.first.nomeProduto);
          final unaccentedToken = foldNomeProdutoForOrder(filterToken);
          final filtered = await runE2eAppResultWithHubRetry(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: MargemProdutoFilter(
                searchTerm: unaccentedToken,
              ),
            ),
            actionLabel: 'margem_produto_loadPage_name_contains',
          );

          filtered.fold(
            (page) {
              expect(page.totalCount, lessThanOrEqualTo(page1.totalCount));
              checkPageInvariants(
                page.items,
                page.totalCount,
                MargemProdutoFilter.defaultPageSize,
              );
              for (final row in page.items) {
                expect(
                  foldNomeProdutoForOrder(row.nomeProduto),
                  contains(unaccentedToken),
                );
              }
              expectNomeProdutoAscending(page.items);
            },
            (failure) {
              expectAcceptableAgentQueriesE2eFailure(
                failure,
                failureScope: 'Repository e2e',
              );
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}

void expectNomeProdutoAscending(List<MargemProdutoRow> items) {
  if (items.length < 2) {
    return;
  }
  for (var i = 0; i < items.length - 1; i++) {
    final nameOrder = foldNomeProdutoForOrder(
      items[i].nomeProduto,
    ).compareTo(foldNomeProdutoForOrder(items[i + 1].nomeProduto));
    expect(
      nameOrder,
      lessThanOrEqualTo(0),
      reason:
          'nomeProduto ASC should not decrease down the page: '
          '"${items[i].nomeProduto}" then "${items[i + 1].nomeProduto}"',
    );
    if (nameOrder == 0) {
      expect(
        items[i].codProduto,
        lessThan(items[i + 1].codProduto),
        reason: 'equal NomeProduto should keep CodProduto ASC',
      );
    }
  }
}

/// SQL Anywhere name order is typically accent-insensitive; Dart code-unit
/// order is not. Fold PT-BR diacritics before comparing E2E page order.
String foldNomeProdutoForOrder(String value) {
  return value
      .toUpperCase()
      .replaceAll('Ç', 'C')
      .replaceAll('Á', 'A')
      .replaceAll('À', 'A')
      .replaceAll('Â', 'A')
      .replaceAll('Ã', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Ê', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ô', 'O')
      .replaceAll('Õ', 'O')
      .replaceAll('Ú', 'U');
}

void checkPageInvariants(
  List<MargemProdutoRow> items,
  int totalCount,
  int pageSize,
) {
  expect(totalCount, greaterThanOrEqualTo(0));
  expect(items.length, lessThanOrEqualTo(pageSize));
  for (final row in items) {
    expect(row.codEmpresa, MargemProdutoFilter.fixedCodEmpresa);
    expect(row.codFilial, MargemProdutoFilter.fixedCodFilial);
    expect(row.codProduto, greaterThan(0));
    expect(row.nomeProduto, isNotEmpty);
    expect(row.nomeFilial, isNotEmpty);
    expect(row.custoReposicao, greaterThanOrEqualTo(0));
    expect(row.precoVendaProduto, greaterThanOrEqualTo(0));
    if (row.custoReposicao <= 0) {
      expect(row.percentualMarkupCustoCompraProduto, 0);
    }
    if (row.precoVendaProduto <= 0) {
      expect(row.margemLucroProduto, 0);
    }
  }
}
