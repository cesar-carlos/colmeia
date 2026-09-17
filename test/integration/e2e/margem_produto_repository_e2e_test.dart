@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_direction.dart';
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
                final nameOrder = foldNomeProdutoForSortOrder(
                  last.nomeProduto,
                ).compareTo(foldNomeProdutoForSortOrder(firstRow.nomeProduto));
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
                  _matchesContainsSearch(row, unaccentedToken, filterToken),
                  isTrue,
                  reason: 'filtered rows must match name, code, group or brand',
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

      test(
        'loadPage contains search matches CodProduto when page 1 has items',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'margem_produto_repository_e2e (code contains)',
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
          if (page1.items.isEmpty) {
            return;
          }

          final codeToken = '${page1.items.first.codProduto}';
          final filtered = await runE2eAppResultWithHubRetry(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: MargemProdutoFilter(searchTerm: codeToken),
            ),
            actionLabel: 'margem_produto_loadPage_code_contains',
          );

          filtered.fold(
            (page) {
              expect(page.totalCount, lessThanOrEqualTo(page1.totalCount));
              checkPageInvariants(
                page.items,
                page.totalCount,
                MargemProdutoFilter.defaultPageSize,
              );
              expect(page.items, isNotEmpty);
              for (final row in page.items) {
                expect(
                  _matchesContainsSearch(row, codeToken, codeToken),
                  isTrue,
                  reason: 'code search must match code, name, group or brand',
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
        'loadPage markup DESC is monotonic on the first page',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'margem_produto_repository_e2e (markup desc)',
          )) {
            return;
          }

          final repository = getIt<MargemProdutoRepository>();
          const filter = MargemProdutoFilter(
            sortBy: MargemProdutoSortBy.percentualMarkup,
            sortDirection: MargemProdutoSortDirection.descending,
          );
          final result = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: filter,
            ),
          );

          result.fold(
            (page) {
              checkPageInvariants(
                page.items,
                page.totalCount,
                MargemProdutoFilter.defaultPageSize,
              );
              expectMarkupDescending(page.items);
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

bool _matchesContainsSearch(
  MargemProdutoRow row,
  String foldedNeedle,
  String rawNeedle,
) {
  final needle = foldedNeedle.toUpperCase();
  return foldNomeProdutoForOrder(row.nomeProduto).contains(needle) ||
      foldNomeProdutoForOrder(row.nomeGrupoProduto ?? '').contains(needle) ||
      foldNomeProdutoForOrder(row.nomeMarca ?? '').contains(needle) ||
      '${row.codProduto}'.contains(rawNeedle);
}

void expectMarkupDescending(List<MargemProdutoRow> items) {
  if (items.length < 2) {
    return;
  }
  for (var i = 0; i < items.length - 1; i++) {
    final current = items[i];
    final next = items[i + 1];
    expect(
      _markupSortKey(current.percentualMarkupCustoCompraProduto),
      greaterThanOrEqualTo(
        _markupSortKey(next.percentualMarkupCustoCompraProduto),
      ),
      reason:
          'markup DESC should not increase down the page: '
          '${current.percentualMarkupCustoCompraProduto} then '
          '${next.percentualMarkupCustoCompraProduto}',
    );
    if (current.percentualMarkupCustoCompraProduto !=
        next.percentualMarkupCustoCompraProduto) {
      continue;
    }
    final nameOrder = foldNomeProdutoForSortOrder(
      current.nomeProduto,
    ).compareTo(foldNomeProdutoForSortOrder(next.nomeProduto));
    expect(
      nameOrder,
      lessThanOrEqualTo(0),
      reason:
          'equal markup should keep NomeProduto ASC: '
          '"${current.nomeProduto}" then "${next.nomeProduto}"',
    );
    if (nameOrder == 0) {
      expect(
        current.codProduto,
        lessThan(next.codProduto),
        reason: 'equal markup and name should keep CodProduto ASC',
      );
    }
  }
}

double _markupSortKey(double? value) => value ?? double.negativeInfinity;

void expectNomeProdutoAscending(List<MargemProdutoRow> items) {
  if (items.length < 2) {
    return;
  }
  for (var i = 0; i < items.length - 1; i++) {
    final nameOrder = foldNomeProdutoForSortOrder(
      items[i].nomeProduto,
    ).compareTo(foldNomeProdutoForSortOrder(items[i + 1].nomeProduto));
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

/// SQL Anywhere name `LIKE` is accent-insensitive; Dart code-unit order is
/// not. Fold PT-BR diacritics before comparing contains matches.
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

/// Dictionary-style ORDER BY also treats punctuation as ignorable. Strip
/// punctuation but keep spaces so `A/B` folds to `AB` without joining words.
String foldNomeProdutoForSortOrder(String value) {
  return foldNomeProdutoForOrder(value)
      .replaceAll(RegExp('[^A-Z0-9 ]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
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
    if (row.custoReposicao == null) {
      expect(row.percentualMarkupCustoCompraProduto, isNull);
      expect(row.margemLucroProduto, isNull);
    } else {
      expect(row.custoReposicao, greaterThanOrEqualTo(0));
      if (row.custoReposicao! <= 0) {
        expect(row.percentualMarkupCustoCompraProduto, 0);
      }
    }
    expect(row.precoVendaProduto, greaterThanOrEqualTo(0));
    if (row.precoVendaProduto <= 0) {
      if (row.custoReposicao == null) {
        expect(row.margemLucroProduto, isNull);
      } else {
        expect(row.margemLucroProduto, 0);
      }
    }
  }
}
