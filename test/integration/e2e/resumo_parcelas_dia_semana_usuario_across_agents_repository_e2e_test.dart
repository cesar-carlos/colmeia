@Tags(['e2e'])
library;

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_across_agents_report.dart';
import 'support/e2e_dependency_bootstrap.dart';

/// Isolated mergeAll smoke for weekday-by-user parcels. Distinct from
/// `load_resumo_parcelas_dia_semana_across_agents_e2e_test.dart` (chart grain).
void main() {
  group(
    'LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'mergeAll loads weekday-user resumo for a known sale window',
        () async {
          if (skipE2eWhenMissingRepositoryKeys(
            'resumo_parcelas_dia_semana_usuario_across_agents_repository_e2e',
          )) {
            return;
          }

          final period = e2eKnownSalesPeriod();
          final useCase =
              getIt<LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase>();
          expectE2eAcrossAgentsReport(
            await runE2eAcrossAgentsResult(
              () => useCase(
                userId: e2eAcrossAgentsUserId,
                filter: ResumoParcelasDiaSemanaFilter(
                  dataVendaInicio: period.start,
                  dataVendaFim: period.end,
                ),
                bridgeTimeoutMs: e2eAcrossAgentsBridgeTimeoutMs,
              ),
            ),
            (row) {
              expect(row.codEmpresa, greaterThan(0));
              expect(row.codFilial, greaterThanOrEqualTo(0));
              expect(row.nomeUsuario, isNotEmpty);
              expect(row.diaSemanaNumero, inInclusiveRange(1, 7));
              expect(row.diaSemana, isNotEmpty);
              expect(row.qtdVendas, greaterThanOrEqualTo(0));
              expect(row.valorParcela, isNonNegative);
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
