@Tags(['e2e'])
library;

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_anual_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_across_agents_report.dart';
import 'support/e2e_dependency_bootstrap.dart';

/// Isolated mergeAll smoke. Kept in its own file so a hung agent SQL cannot
/// poison sibling across-agent reports on the socket channel.
void main() {
  group(
    'LoadResumoParcelasAnualAcrossAgentsUseCase (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'mergeAll loads annual parcels resumo for a known sale window',
        () async {
          if (skipE2eWhenMissingRepositoryKeys(
            'resumo_parcelas_anual_across_agents_repository_e2e',
          )) {
            return;
          }

          final period = e2eKnownSalesPeriod();
          final useCase = getIt<LoadResumoParcelasAnualAcrossAgentsUseCase>();
          expectE2eAcrossAgentsReport(
            await runE2eAcrossAgentsResult(
              () => useCase(
                userId: e2eAcrossAgentsUserId,
                filter: ResumoParcelasAnualFilter(
                  dataVendaInicio: period.start,
                  dataVendaFim: period.end,
                ),
                bridgeTimeoutMs: e2eAcrossAgentsBridgeTimeoutMs,
              ),
            ),
            (row) {
              expect(row.codEmpresa, greaterThan(0));
              expect(row.codFilial, greaterThanOrEqualTo(0));
              expect(row.anoDataVenda, greaterThan(1900));
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.valorTotalVenda, isNonNegative);
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
