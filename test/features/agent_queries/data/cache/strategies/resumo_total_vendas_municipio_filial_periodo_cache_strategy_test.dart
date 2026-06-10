import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_vendas_municipio_filial_periodo_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strategy = ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy();

  group('ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy', () {
    test('planBuckets splits closed and open days', () {
      final clock = DateTime(2026, 6, 3);
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3),
      );

      final plan = strategy.planBuckets(
        filter: filter,
        clock: clock,
        policy: AgentQueryLoadPolicy.defaultLoad,
      );

      expect(plan.closedBucketIds, ['2026-06-01', '2026-06-02']);
      expect(plan.openBucketIds, ['2026-06-03']);
      expect(plan.networkBucketIds, ['2026-06-03']);
    });

    test('cacheScopeId includes selected branch pushdown', () {
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3),
        selectedBranches:
            const <ResumoTotalVendasMunicipioFilialPeriodoBranchRef>[
              ResumoTotalVendasMunicipioFilialPeriodoBranchRef(
                agentId: 'agent-b',
                codEmpresa: 1,
                codFilial: 2,
              ),
              ResumoTotalVendasMunicipioFilialPeriodoBranchRef(
                agentId: 'agent-a',
                codEmpresa: 1,
                codFilial: 1,
              ),
            ],
      );

      expect(
        strategy.cacheScopeId(filter),
        contains('br:agent-a:1:1,agent-b:1:2'),
      );
    });
  });
}
