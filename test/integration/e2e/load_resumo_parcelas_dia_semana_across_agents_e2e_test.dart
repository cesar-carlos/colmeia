import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Exercises the same stack as the overview weekday sales chart: target
/// resolution (stubbed approved agents + local tokens), plan, executor, and
/// `ResumoParcelasDiaSemanaSql` for the default overview sale window (current
/// calendar month).
void main() {
  group(
    'LoadResumoParcelasDiaSemanaAcrossAgentsUseCase (e2e)',
    () {
      test(
        'mergeAll loads weekday resumo for the overview default month window',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Same skip hint pattern as other agent-query e2e tests (local/CI).
            // ignore: avoid_print
            print(
              'SKIP load_resumo_parcelas_dia_semana_across_agents_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final clock = DateTime.now();
          final overviewFilter = OverviewFilter.initial(now: clock);
          final yearMonth = overviewFilter.yearMonth!;
          final filter = ResumoParcelasDiaSemanaFilter(
            dataVendaInicio: yearMonth.start,
            dataVendaFim: yearMonth.end,
          );

          final useCase = getIt<LoadResumoParcelasDiaSemanaAcrossAgentsUseCase>();
          final result = await useCase(
            userId: 'e2e-overview-user',
            filter: filter,
            bridgeTimeoutMs: 300000,
          );

          result.fold(
            (report) {
              final chartRows = report.chartRowsWeek;
              expect(chartRows.length, 7);
              for (var i = 0; i < chartRows.length; i++) {
                final row = chartRows[i];
                expect(row.diaSemanaNumero, i + 1);
                expect(row.diaSemana, isNotEmpty);
                expect(row.codEmpresa, ResumoParcelasDiaSemanaRow.aggregatedBranchSentinel);
                expect(row.codFilial, ResumoParcelasDiaSemanaRow.aggregatedBranchSentinel);
                expect(row.qtdVendas, greaterThanOrEqualTo(0));
                expect(row.valorParcela, isNonNegative);
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
                    'Across-agents e2e should return rows, invalid_policy / '
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
