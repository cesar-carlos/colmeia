@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'ProdutoVendidoTendenciaDeVendaMediaMovelRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'loadPage executes the real moving-average trend query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Intentional stdout for local troubleshooting when E2E env is missing.
            // ignore: avoid_print
            print(
              'SKIP produto_vendido_tendencia_de_venda_media_movel_repository_e2e: '
              'missing ${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository =
              getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>();

          final result = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
                quantidadeDias: 7,
                pageSize: 10,
              ),
            ),
          );

          result.fold(
            (page) {
              checkPageInvariants(page.items, page.totalCount, 10);
            },
            (failure) {
              expect(
                failure,
                isNot(isA<SessionFailure>()),
                reason:
                    'Unexpected HTTP 401 after client login '
                    '- check E2E_* values.',
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
            // Intentional stdout for local troubleshooting when E2E env is missing.
            // ignore: avoid_print
            print(
              'SKIP produto_vendido_tendencia_de_venda_media_movel_repository_e2e '
              '(page 2): missing ${missingKeys.join(', ')}.',
            );
            return;
          }

          final repository =
              getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>();

          const smallPageSize = 5;
          final first = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
                quantidadeDias: 7,
                pageSize: smallPageSize,
              ),
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
          final second = await runE2eAppResultWithHubRetry(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
                quantidadeDias: 7,
                page: 2,
                pageSize: smallPageSize,
              ),
            ),
            actionLabel: 'produto_vendido_tendencia_media_movel_loadPage_page2',
          );

          second.fold(
            (page2) {
              expect(page2.totalCount, totalCount);
              expect(page2.items.length, lessThanOrEqualTo(smallPageSize));
              checkPageInvariants(page2.items, page2.totalCount, smallPageSize);
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

      test('loadSummary executes the real summary query', () async {
        final missingKeys = missingE2eRepositoryKeys();
        if (missingKeys.isNotEmpty) {
          // Intentional stdout for local troubleshooting when E2E env is missing.
          // ignore: avoid_print
          print(
            'SKIP produto_vendido_tendencia_de_venda_media_movel_repository_e2e '
            '(summary): missing ${missingKeys.join(', ')}.',
          );
          return;
        }

        final repository =
            getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>();

        final result = await runE2eAppResultWithHubRetry(
          () => repository.loadSummary(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
              quantidadeDias: 7,
            ),
          ),
          actionLabel: 'produto_vendido_tendencia_media_movel_loadSummary',
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
        'loadPageAndSummary returns page and summary in one batch round-trip',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            /// E2E: explain skip when repository keys are not configured.
            // ignore: avoid_print
            print(
              'SKIP produto_vendido_tendencia_de_venda_media_movel_repository_e2e '
              '(batch): missing ${missingKeys.join(', ')}.',
            );
            return;
          }

          final repository =
              getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>();

          final result = await runE2eAppResultWithHubRetry(
            () => repository.loadPageAndSummary(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
                quantidadeDias: 7,
                pageSize: 10,
              ),
            ),
            actionLabel: 'produto_vendido_tendencia_media_movel_batch',
          );

          result.fold(
            (data) {
              checkPageInvariants(data.page.items, data.page.totalCount, 10);
              checkSummaryInvariants(data.summaryRows);
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

void checkPageInvariants(
  List<ProdutoVendidoTendenciaDeVendaMediaMovelRow> items,
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
    expect(row.codUnidadeMedida, isNotEmpty);
    expect(row.mediaAtual, isNotNaN);
    expect(row.mediaAnterior, isNotNaN);
    expect(row.tendenciaPercentual, isNotNaN);
    expect(row.classificacao, isNotEmpty);
  }
}

void checkSummaryInvariants(
  List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> items,
) {
  for (final row in items) {
    expect(row.classificacao, isNotEmpty);
    expect(row.quantidadeProdutos, greaterThanOrEqualTo(0));
    expect(row.impactoLiquido, isNotNaN);
  }
}
