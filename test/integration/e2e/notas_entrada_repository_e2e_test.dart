@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_agent_queries_test_helpers.dart';

void main() {
  group(
    'NotasEntradaRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test('loadPage executes the numbered entrada notes query', () async {
        if (shouldSkipE2eRepositoryTest('notas_entrada_repository_e2e')) {
          return;
        }

        final repository = getIt<NotasEntradaRepository>();
        final filter = NotasEntradaFilter(pageSize: 25);
        final result = await runE2eAppResult(
          () => repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: filter,
          ),
        );

        NotasEntradaPageResult? firstPage;
        result.fold(
          (page) {
            firstPage = page;
            expect(page.items.length, lessThanOrEqualTo(filter.pageSize));
            expect(page.totalCount, greaterThanOrEqualTo(page.items.length));
            for (final row in page.items) {
              expect(row.compraId, greaterThan(0));
              expect(row.codEmpresa, 1);
              expect(row.codFilial, 1);
              expect(row.nomeFilial, isNotEmpty);
              expect(row.numeroDocumento, isNotEmpty);
              expect(row.dataLancamento, isNotNull);
              expect(row.nomeFornecedor, isNotEmpty);
            }
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
            final firstPageIds = page.items.map((row) => row.compraId).toSet();
            expect(
              nextPage.items.any((row) => firstPageIds.contains(row.compraId)),
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
        'loadPage applies a supplier search to the numbered catalog',
        () async {
          if (shouldSkipE2eRepositoryTest('notas_entrada_repository_e2e')) {
            return;
          }

          final repository = getIt<NotasEntradaRepository>();
          final unfiltered = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: NotasEntradaFilter(pageSize: 25),
            ),
          );

          NotasEntradaPageResult? catalog;
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
