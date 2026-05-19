@Tags(['e2e'])
library;

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

void main() {
  group(
    'LoadCadastroFilialAcrossAgentsUseCase (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test('mergeAll loads paged branch catalog rows', () async {
        final missingKeys = missingE2eRepositoryKeys();
        if (missingKeys.isNotEmpty) {
          // E2E skip hint; `print` is intentional for local diagnostics.
          // ignore: avoid_print
          print(
            'SKIP cadastro_filial_across_agents_repository_e2e: missing '
            '${missingKeys.join(', ')}. '
            'Set them in assets/env/local.env, process env, or --dart-define.',
          );
          return;
        }

        final useCase = getIt<LoadCadastroFilialAcrossAgentsUseCase>();
        final result = await runE2eAppResult(
          () => useCase(
            userId: 'e2e-user',
            filter: const CadastroFilialFilter(),
            bridgeTimeoutMs: 300000,
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
                'Across-agents e2e should return rows, invalid_policy / '
                'missing_permission RPC, or transient bridge HTTP 5xx.',
          );
          return;
        }

        expect(page.totalCount, greaterThanOrEqualTo(0));
        for (final participant in page.report.participants) {
          if (participant.isSuccess) {
            expect(participant.rows.length, lessThanOrEqualTo(20));
          }
        }
        for (final row in page.report.mergedRows) {
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

        AgentQueryExecutionParticipant<CadastroFilialRow>? seededParticipant;
        for (final participant in page.report.participants) {
          if (participant.isSuccess && participant.rows.length >= 2) {
            seededParticipant = participant;
            break;
          }
        }
        if (seededParticipant == null) {
          return;
        }
        final participant = seededParticipant;

        final selectedRows = participant.rows
            .take(2)
            .toList(
              growable: false,
            );
        final subsetResult = await runE2eAppResult(
          () => useCase.loadAll(
            userId: 'e2e-user',
            filter: CadastroFilialFilter(
              selectedBranches: selectedRows
                  .map(
                    (row) => CadastroFilialBranchRef(
                      agentId: participant.agentId,
                      codEmpresa: row.codEmpresa,
                      codFilial: row.codFilial,
                    ),
                  )
                  .toList(growable: false),
            ),
            selectedAgentIds: <String>{participant.agentId},
            bridgeTimeoutMs: 300000,
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
                'Across-agents e2e should return rows, invalid_policy / '
                'missing_permission RPC, or transient bridge HTTP 5xx.',
          );
          return;
        }

        final expectedIds = selectedRows
            .map((row) => '${row.codEmpresa}:${row.codFilial}')
            .toSet();
        final actualIds = subsetPage.report.mergedRows
            .map((row) => '${row.codEmpresa}:${row.codFilial}')
            .toSet();
        expect(actualIds, expectedIds);
      });
    },
    tags: <String>['e2e'],
  );
}
