@Tags(['e2e'])
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report_resumo_parcelas.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/overview_last_twelve_months_venda_range.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Exercises the same stack as the overview home monthly chart: target
/// resolution (stubbed approved agents + local tokens), plan, executor, and
/// `ResumoParcelasMensalSql` over the last-twelve-months sale window.
void main() {
  group(
    'LoadResumoParcelasMensalAcrossAgentsUseCase (e2e)',
    () {
      test(
        'mergeAll loads monthly resumo for the overview twelve-month window',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // Same skip hint pattern as other agent-query e2e tests (local/CI).
            // ignore: avoid_print
            print(
              'SKIP resumo_parcelas_mensal_across_agents_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final clock = DateTime.now();
          final overviewFilter = OverviewFilter.initial(now: clock);
          final last12 = OverviewLast12MonthsVendaRange.fromOverviewFilter(
            overviewFilter,
            clock: () => clock,
          );
          final filter = ResumoParcelasMensalFilter(
            dataVendaInicio: last12.dataVendaInicio,
            dataVendaFim: last12.dataVendaFim,
          );

          final useCase = getIt<LoadResumoParcelasMensalAcrossAgentsUseCase>();
          final result = await useCase(
            userId: 'e2e-overview-user',
            filter: filter,
            bridgeTimeoutMs: 300000,
          );

          result.fold(
            (report) {
              final chartRows = report.chartRowsFilledPeriod(filter);
              expect(chartRows.length, greaterThanOrEqualTo(12));
              for (final row in chartRows) {
                expect(row.ano, greaterThan(1900));
                expect(row.mes, inInclusiveRange(1, 12));
                expect(row.qtdVendas, greaterThanOrEqualTo(0));
                expect(row.valorParcela, isNonNegative);
                expect(row.anoMes, matches(RegExp(r'^\d{4}/\d{2}$')));
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
