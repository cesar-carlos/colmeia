@Tags(['e2e'])
library;

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_across_agents_report.dart';
import 'support/e2e_dependency_bootstrap.dart';

/// Isolated mergeAll smoke. Kept in its own file so a hung agent SQL cannot
/// poison sibling across-agent reports on the socket channel.
void main() {
  group(
    'LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase (e2e)',
    () {
      registerE2eAgentQueriesSuiteHooks();

      test(
        'mergeAll loads payment-method resumo for a known sale window',
        () async {
          if (skipE2eWhenMissingRepositoryKeys(
            'resumo_parcela_forma_pagamento_across_agents_repository_e2e',
          )) {
            return;
          }

          final period = e2eKnownSalesPeriod();
          final useCase =
              getIt<LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase>();
          expectE2eAcrossAgentsReport(
            await runE2eAcrossAgentsResult(
              () => useCase(
                userId: e2eAcrossAgentsUserId,
                filter: ResumoParcelaFormaPagamentoFilter(
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
              expect(row.anoDataVenda, greaterThan(1900));
              expect(row.mesDataVenda, inInclusiveRange(1, 12));
              expect(row.codFormaPagamento, isNotEmpty);
              expect(row.descricaoFormaPagamento, isNotEmpty);
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
