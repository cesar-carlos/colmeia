@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_resumo_fornecedor_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_resumo_fornecedor_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_agent_queries_test_helpers.dart';

void main() {
  group(
    'NotasEntradaResumoFornecedorRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test('loadPage executes the grouped supplier totals query', () async {
        if (shouldSkipE2eRepositoryTest(
          'notas_entrada_resumo_fornecedor_repository_e2e',
        )) {
          return;
        }

        final repository = getIt<NotasEntradaResumoFornecedorRepository>();
        final filter = NotasEntradaFilter(pageSize: 25);
        final result = await runE2eAppResult(
          () => repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: filter,
          ),
        );

        NotasEntradaResumoFornecedorPageResult? firstPage;
        result.fold(
          (page) {
            firstPage = page;
            expect(page.items.length, lessThanOrEqualTo(filter.pageSize));
            expect(page.totalCount, greaterThanOrEqualTo(page.items.length));
            expect(page.totalValorCompra, greaterThanOrEqualTo(0));
            var pageSum = 0.0;
            for (final row in page.items) {
              expect(row.codEmpresa, 1);
              expect(row.codFilial, 1);
              expect(row.nomeFilial, isNotEmpty);
              expect(row.codFornecedor, greaterThan(0));
              expect(row.nomeFornecedor, isNotEmpty);
              expect(row.qtdNotas, greaterThanOrEqualTo(1));
              expect(row.ticketMedio, greaterThanOrEqualTo(0));
              expect(row.valorTotalCompra, greaterThanOrEqualTo(0));
              pageSum += row.valorTotalCompra;
            }
            expect(page.totalValorCompra, greaterThanOrEqualTo(pageSum));
          },
          (failure) => expectAcceptableAgentQueriesE2eFailure(
            failure,
            failureScope: 'Repository e2e',
          ),
        );

        final page = firstPage;
        if (page == null || page.items.isEmpty || page.totalCount <= 25) {
          return;
        }

        final nextResult = await repository.loadPage(
          userId: 'user-1',
          agentId: AppEnvironment.e2eAgentId,
          clientToken: AppEnvironment.e2eClientToken,
          filter: filter.copyWith(page: 2),
        );
        nextResult.fold(
          (nextPage) {
            expect(nextPage.totalCount, page.totalCount);
            expect(nextPage.totalValorCompra, page.totalValorCompra);
            final firstPageCodes = page.items
                .map((row) => row.codFornecedor)
                .toSet();
            expect(
              nextPage.items.any(
                (row) => firstPageCodes.contains(row.codFornecedor),
              ),
              isFalse,
            );
          },
          (failure) => expectAcceptableAgentQueriesE2eFailure(
            failure,
            failureScope: 'Numbered continuation repository e2e',
          ),
        );
      });

      test(
        'loadPage applies a supplier search to the grouped catalog',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'notas_entrada_resumo_fornecedor_repository_e2e',
          )) {
            return;
          }

          final repository = getIt<NotasEntradaResumoFornecedorRepository>();
          final unfiltered = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: NotasEntradaFilter(pageSize: 25),
            ),
          );

          NotasEntradaResumoFornecedorPageResult? catalog;
          unfiltered.fold(
            (page) => catalog = page,
            (failure) => expectAcceptableAgentQueriesE2eFailure(
              failure,
              failureScope: 'Supplier search baseline repository e2e',
            ),
          );
          final baseline = catalog;
          if (baseline == null || baseline.items.isEmpty) {
            return;
          }

          final supplierName = baseline.items.first.nomeFornecedor.trim();
          if (supplierName.isEmpty) {
            return;
          }

          final searched = await repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: NotasEntradaFilter(
              pageSize: 25,
              searchTerm: supplierName,
            ),
          );
          searched.fold(
            (page) {
              expect(page.totalCount, lessThanOrEqualTo(baseline.totalCount));
              expect(page.items, isNotEmpty);
              final expectedCode = baseline.items.first.codFornecedor;
              expect(
                page.items.every((row) => row.codFornecedor == expectedCode),
                isTrue,
              );
            },
            (failure) => expectAcceptableAgentQueriesE2eFailure(
              failure,
              failureScope: 'Supplier search repository e2e',
            ),
          );
        },
      );
    },
  );
}
