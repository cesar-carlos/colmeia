@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_itens_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_agent_queries_test_helpers.dart';
import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'NotasEntradaItensRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'load executes the line-item query for a catalog purchase',
        () async {
          if (shouldSkipE2eRepositoryTest(
            'notas_entrada_itens_repository_e2e',
          )) {
            return;
          }

          final notesRepository = getIt<NotasEntradaRepository>();
          final notesResult = await runE2eAppResult(
            () => notesRepository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: NotasEntradaFilter(pageSize: 1),
            ),
          );

          var compraId = 0;
          var codEmpresa = NotasEntradaFilter.defaultCodEmpresa;
          var codFilial = NotasEntradaFilter.defaultCodFilial;
          notesResult.fold(
            (page) {
              if (page.items.isNotEmpty) {
                final note = page.items.first;
                compraId = note.compraId;
                codEmpresa = note.codEmpresa;
                codFilial = note.codFilial;
              }
            },
            (failure) => expectAcceptableAgentQueriesE2eFailure(
              failure,
              failureScope: 'Notes catalog for items e2e',
            ),
          );
          if (compraId <= 0) {
            return;
          }

          final repository = getIt<NotasEntradaItensRepository>();
          final result = await runE2eAppResult(
            () => repository.load(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: NotasEntradaItensFilter(compraId: compraId),
            ),
          );

          result.fold(
            (page) {
              for (final row in page.items) {
                expect(row.compraId, compraId);
                expect(row.codEmpresa, codEmpresa);
                expect(row.codFilial, codFilial);
                expect(row.codProduto, greaterThan(0));
                expect(row.nomeProduto, isNotEmpty);
                expect(row.quantidade, greaterThanOrEqualTo(0));
                expect(row.valorTotal, greaterThanOrEqualTo(0));
              }
            },
            (failure) => expectAcceptableAgentQueriesE2eFailure(
              failure,
              failureScope: 'Repository e2e',
            ),
          );
        },
      );

      test('load returns line items for CompraId 178183482', () async {
        if (shouldSkipE2eRepositoryTest(
          'notas_entrada_itens_compra_178183482_e2e',
        )) {
          return;
        }

        const compraId = 178183482;
        final repository = getIt<NotasEntradaItensRepository>();
        final result = await runE2eAppResult(
          () => repository.load(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: const NotasEntradaItensFilter(compraId: compraId),
          ),
        );

        result.fold(
          (page) {
            // E2E diagnostic for this fixed purchase id.
            // ignore: avoid_print
            print(
              'CompraId $compraId returned ${page.items.length} item(s)'
              '${page.isTruncated ? ' (truncated)' : ''}.',
            );
            expect(page.items, isNotEmpty);
            for (final row in page.items) {
              expect(row.compraId, compraId);
              expect(row.codProduto, greaterThan(0));
              expect(row.nomeProduto, isNotEmpty);
              expect(row.quantidade, greaterThanOrEqualTo(0));
              expect(row.valorTotal, greaterThanOrEqualTo(0));
            }
          },
          (failure) {
            fail(
              'CompraId $compraId item query failed: '
              '${e2eAgentSqlFailureDiagnostic(failure)}',
            );
          },
        );
      });
    },
    tags: <String>['e2e'],
  );
}
