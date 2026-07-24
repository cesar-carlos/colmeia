@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/sales_trend_classificacao.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_trend_date_preset.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ProdutoVendidoTendenciaDeVendaRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'loadAll executes the real trend query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Intentional stdout for local troubleshooting when E2E env is missing.
            // ignore: avoid_print
            print(
              'SKIP produto_vendido_tendencia_de_venda_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository = getIt<ProdutoVendidoTendenciaDeVendaRepository>();

          final result = await runE2eAppResult(
            () => repository.loadAll(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: e2eProdutoTendenciaVendaFilter(),
            ),
          );

          result.fold(
            (rows) {
              for (final row in rows) {
                expect(row.codEmpresa, greaterThan(0));
                expect(row.codFilial, greaterThanOrEqualTo(0));
                expect(row.codProduto, greaterThan(0));
                expect(row.nomeProduto, isNotEmpty);
                expect(row.codUnidadeMedida, isNotEmpty);
                expect(row.qtdAnterior, isNonNegative);
                expect(row.qtdAtual, isNonNegative);
                expect(row.percentualTendencia, isNotNaN);
                expect(row.classificacao, isNotEmpty);
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
              if (shouldLogE2eAcceptedFailureDiagnostic(failure)) {
                // ignore: avoid_print -- E2E failure diagnostics for local triage.
                print(
                  'produto_vendido_tendencia_de_venda_repository_e2e failure: '
                  '${e2eAgentSqlFailureDiagnostic(failure)}',
                );
              }
              expect(
                isAcceptableE2eAgentSqlRepositoryFailure(failure),
                isTrue,
                reason:
                    'Repository e2e should return rows, invalid_policy / '
                    'missing_permission RPC, or transient bridge HTTP 5xx. '
                    '${e2eAgentSqlFailureDiagnostic(failure)}',
              );
            },
          );
        },
      );

      test('loadSummary executes the real summary query', () async {
        final missingKeys = missingE2eRepositoryKeys();
        if (missingKeys.isNotEmpty) {
          // Intentional stdout for local troubleshooting when E2E env is missing.
          // ignore: avoid_print
          print(
            'SKIP produto_vendido_tendencia_de_venda_repository_e2e '
            '(summary): missing ${missingKeys.join(', ')}.',
          );
          return;
        }

        final repository = getIt<ProdutoVendidoTendenciaDeVendaRepository>();

        final result = await runE2eAppResult(
          () => repository.loadSummary(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: e2eProdutoTendenciaVendaFilter(),
          ),
        );

        result.fold(
          checkSummaryInvariants,
          (failure) {
            expect(
              failure,
              isNot(isA<SessionFailure>()),
              reason: 'Unexpected HTTP 401 after client login.',
            );
            expect(
              isAcceptableE2eAgentSqlRepositoryFailure(failure),
              isTrue,
            );
          },
        );
      });

      test(
        'use case executes the same trend query (stack path)',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Intentional stdout for local troubleshooting when E2E env is missing.
            // ignore: avoid_print
            print(
              'SKIP load_produto_vendido_tendencia_de_venda use_case e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final useCase = getIt<LoadProdutoVendidoTendenciaDeVendaUseCase>();

          final result = await runE2eAppResultWithHubRetry(
            () => useCase(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: e2eProdutoTendenciaVendaFilter(),
            ),
            actionLabel: 'load_produto_vendido_tendencia_de_venda_use_case',
          );

          result.fold(
            (page) {
              for (final row in page.items) {
                expect(row.codProduto, greaterThan(0));
                expect(row.classificacao, isNotEmpty);
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

      test(
        'loadPageAndSummary page 2 shares totalCount when more than one page exists',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip diagnostics are printed when required env keys are absent.
            // ignore: avoid_print
            print(
              'SKIP produto_vendido_tendencia_de_venda_repository_e2e '
              '(page 2): missing ${missingKeys.join(', ')}.',
            );
            return;
          }

          final repository = getIt<ProdutoVendidoTendenciaDeVendaRepository>();
          const smallPageSize = 5;
          final summaryFilter = e2eProdutoTendenciaVendaFilter();

          final first = await runE2eAppResult(
            () => repository.loadPageAndSummary(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              pageFilter: ProdutoVendidoTendenciaDeVendaFilter(
                periodoAtualInicio: summaryFilter.periodoAtualInicio,
                periodoAtualFim: summaryFilter.periodoAtualFim,
                periodoAnteriorInicio: summaryFilter.periodoAnteriorInicio,
                periodoAnteriorFim: summaryFilter.periodoAnteriorFim,
                pageSize: smallPageSize,
              ),
              summaryFilter: summaryFilter,
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
          checkPagedTrendInvariants(
            page1.rows,
            page1.totalCount,
            smallPageSize,
          );
          if (page1.totalCount <= smallPageSize) {
            return;
          }

          final totalCount = page1.totalCount;
          final second = await runE2eAppResultWithHubRetry(
            () => repository.loadPageAndSummary(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              pageFilter: ProdutoVendidoTendenciaDeVendaFilter(
                periodoAtualInicio: summaryFilter.periodoAtualInicio,
                periodoAtualFim: summaryFilter.periodoAtualFim,
                periodoAnteriorInicio: summaryFilter.periodoAnteriorInicio,
                periodoAnteriorFim: summaryFilter.periodoAnteriorFim,
                page: 2,
                pageSize: smallPageSize,
              ),
              summaryFilter: summaryFilter,
            ),
            actionLabel: 'produto_vendido_tendencia_loadPageAndSummary_page2',
          );

          second.fold(
            (page2) {
              expect(page2.totalCount, totalCount);
              expect(page2.rows.length, lessThanOrEqualTo(smallPageSize));
              checkPagedTrendInvariants(
                page2.rows,
                page2.totalCount,
                smallPageSize,
              );

              if (page1.rows.isNotEmpty && page2.rows.isNotEmpty) {
                String key(ProdutoVendidoTendenciaDeVendaRow row) =>
                    '${row.codEmpresa}-${row.codFilial}-${row.codProduto}';
                final keys1 = page1.rows.map(key).toSet();
                final overlap = page2.rows
                    .where((row) => keys1.contains(key(row)))
                    .toList();
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
        'loadPageAndSummary returns page, summary, and top movers in one round-trip',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip diagnostics are printed when required env keys are absent.
            // ignore: avoid_print
            print(
              'SKIP produto_vendido_tendencia_de_venda_repository_e2e '
              '(screen): missing ${missingKeys.join(', ')}.',
            );
            return;
          }

          final repository = getIt<ProdutoVendidoTendenciaDeVendaRepository>();
          final filter = e2eProdutoTendenciaVendaFilter(pageSize: 10);

          final result = await runE2eAppResultWithHubRetry(
            () => repository.loadPageAndSummary(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              pageFilter: filter,
              summaryFilter: filter,
            ),
            actionLabel: 'produto_vendido_tendencia_batch',
          );

          result.fold(
            (data) {
              expect(data.totalCount, greaterThanOrEqualTo(0));
              expect(data.rows.length, lessThanOrEqualTo(filter.pageSize));
              if (data.totalCount > 0) {
                expect(data.rows, isNotEmpty);
              } else {
                expect(data.rows, isEmpty);
              }
              checkTrendRowsInvariants(data.rows);
              checkSummaryInvariants(data.summaryRows);
              checkTrendRowsInvariants(data.topGainers);
              checkTrendRowsInvariants(data.topLosers);
              expect(
                data.topGainers.length,
                lessThanOrEqualTo(
                  ProdutoVendidoTendenciaDeVendaSql.topMoversLimit,
                ),
              );
              expect(
                data.topLosers.length,
                lessThanOrEqualTo(
                  ProdutoVendidoTendenciaDeVendaSql.topMoversLimit,
                ),
              );
              for (final row in data.topGainers) {
                expect(row.diferenca, greaterThan(0));
              }
              for (final row in data.topLosers) {
                expect(row.diferenca, lessThan(0));
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
    },
    tags: <String>['e2e'],
  );
}

void checkPagedTrendInvariants(
  List<ProdutoVendidoTendenciaDeVendaRow> rows,
  int totalCount,
  int pageSize,
) {
  expect(totalCount, greaterThanOrEqualTo(0));
  expect(rows.length, lessThanOrEqualTo(pageSize));
  if (totalCount > 0) {
    expect(rows, isNotEmpty);
  } else {
    expect(rows, isEmpty);
  }
  checkTrendRowsInvariants(rows);
}

void checkTrendRowsInvariants(List<ProdutoVendidoTendenciaDeVendaRow> rows) {
  for (final row in rows) {
    expect(row.codEmpresa, greaterThan(0));
    expect(row.codFilial, greaterThanOrEqualTo(0));
    expect(row.codProduto, greaterThan(0));
    expect(row.nomeProduto, isNotEmpty);
    expect(row.codUnidadeMedida, isNotEmpty);
    expect(row.qtdAnterior, isNonNegative);
    expect(row.qtdAtual, isNonNegative);
    expect(row.percentualTendencia, isNotNaN);
    expect(
      SalesTrendClassificacao.allowed.contains(row.classificacao),
      isTrue,
      reason: 'unexpected classificacao ${row.classificacao}',
    );
  }
}

/// Month-to-date atual + aligned anterior window (same preset as the app UI).
///
/// Uses [DateTime.now] so E2E targets the live month on fresh databases that
/// only have current-month movement.
ProdutoVendidoTendenciaDeVendaFilter e2eProdutoTendenciaVendaFilter({
  DateTime? anchor,
  int page = 1,
  int pageSize = ProdutoVendidoTendenciaDeVendaFilter.defaultPageSize,
}) {
  final periodoAtual = salesTrendMonthToDateInclusiveRange(
    anchor ?? DateTime.now(),
  );
  final periodoAnterior = salesTrendAutoPreviousRange(periodoAtual);
  return ProdutoVendidoTendenciaDeVendaFilter(
    periodoAtualInicio: periodoAtual.start,
    periodoAtualFim: periodoAtual.end,
    periodoAnteriorInicio: periodoAnterior.start,
    periodoAnteriorFim: periodoAnterior.end,
    page: page,
    pageSize: pageSize,
  );
}

void checkSummaryInvariants(
  List<ProdutoVendidoTendenciaDeVendaSummaryRow> rows,
) {
  for (final row in rows) {
    expect(
      SalesTrendClassificacao.allowed.contains(row.classificacao),
      isTrue,
      reason: 'unexpected classificacao ${row.classificacao}',
    );
    expect(row.quantidadeProdutos, greaterThanOrEqualTo(0));
    expect(row.impactoLiquido, isNotNaN);
  }
}
