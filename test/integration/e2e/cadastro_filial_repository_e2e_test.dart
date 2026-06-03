@Tags(['e2e'])
library;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/cadastro_filial_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'CadastroFilialRepository (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'loadPage page 1 executes the real branch catalog query',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP cadastro_filial_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          final repository = getIt<CadastroFilialRepository>();

          final result = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: const CadastroFilialFilter(),
            ),
          );

          final page = result.getOrNull();
          if (page == null) {
            final failure = result.exceptionOrNull()!;
            expect(
              failure,
              isNot(isA<SessionFailure>()),
              reason:
                  'Unexpected HTTP 401 after client login '
                  'Ã¢â‚¬â€ check E2E_* values.',
            );
            expect(
              isAcceptableE2eAgentSqlRepositoryFailure(failure),
              isTrue,
              reason:
                  'Repository e2e should return rows, invalid_policy / '
                  'missing_permission RPC, or transient bridge HTTP 5xx.',
            );
            return;
          }

          expect(page.totalCount, greaterThanOrEqualTo(0));
          expect(
            page.items.length,
            lessThanOrEqualTo(CadastroFilialFilter.defaultPageSize),
          );
          expect(
            page.items.length,
            lessThanOrEqualTo(
              AgentQueriesBoundedResultMaxRows.cadastroFilialPage,
            ),
          );
          for (final row in page.items) {
            expect(row.codEmpresa, greaterThan(0));
            expect(row.codFilial, greaterThanOrEqualTo(0));
            expect(row.nomeFilial, isNotEmpty);
            final cep = row.cep;
            if (cep != null) {
              expect(cep, matches(RegExp(r'^\d+$')));
            }
            final municipio = row.nomeMunicipio;
            if (municipio != null) {
              expect(municipio, municipio.trim());
              expect(municipio, isNotEmpty);
            }
          }

          if (page.items.length < 2) {
            return;
          }

          final selectedRows = page.items.take(2).toList(growable: false);
          final subsetResult = await runE2eAppResult(
            () => repository.loadPage(
              userId: 'user-1',
              agentId: AppEnvironment.e2eAgentId,
              clientToken: AppEnvironment.e2eClientToken,
              filter: CadastroFilialFilter(
                selectedBranches: selectedRows
                    .map(
                      (row) => CadastroFilialBranchRef(
                        agentId: AppEnvironment.e2eAgentId,
                        codEmpresa: row.codEmpresa,
                        codFilial: row.codFilial,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          );

          final subsetPage = subsetResult.getOrNull();
          if (subsetPage == null) {
            final failure = subsetResult.exceptionOrNull()!;
            expect(
              failure,
              isNot(isA<SessionFailure>()),
              reason:
                  'Unexpected HTTP 401 after client login '
                  'Ã¢â‚¬â€ check E2E_* values.',
            );
            expect(
              isAcceptableE2eAgentSqlRepositoryFailure(failure),
              isTrue,
              reason:
                  'Repository e2e should return rows, invalid_policy / '
                  'missing_permission RPC, or transient bridge HTTP 5xx.',
            );
            return;
          }

          final expectedIds = selectedRows
              .map((row) => '${row.codEmpresa}:${row.codFilial}')
              .toSet();
          final actualIds = subsetPage.items
              .map((row) => '${row.codEmpresa}:${row.codFilial}')
              .toSet();
          expect(actualIds, expectedIds);
        },
      );
    },
    tags: <String>['e2e'],
  );
}
