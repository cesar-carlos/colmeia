import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_vendas_municipio_filial_periodo_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/cache/calendar_bucket_closure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strategy = ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy();

  group('ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy', () {
    test('planBuckets uses one period-range bucket (not per-day)', () {
      final clock = DateTime(2026, 6, 3);
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3),
      );
      final bucketId = CalendarBucketClosure.periodRangeBucketId(
        start: filter.dataVendaInicio,
        end: filter.dataVendaFim,
      );

      final plan = strategy.planBuckets(
        filter: filter,
        clock: clock,
        policy: AgentQueryLoadPolicy.defaultLoad,
      );

      expect(plan.allBucketIdsInRange, [bucketId]);
      expect(plan.openBucketIds, [bucketId]);
      expect(plan.closedBucketIds, isEmpty);
      expect(plan.networkBucketIds, [bucketId]);
    });

    test('fully closed range is a single closed bucket', () {
      final clock = DateTime(2026, 6, 10);
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3),
      );
      final bucketId = CalendarBucketClosure.periodRangeBucketId(
        start: filter.dataVendaInicio,
        end: filter.dataVendaFim,
      );

      final plan = strategy.planBuckets(
        filter: filter,
        clock: clock,
        policy: AgentQueryLoadPolicy.defaultLoad,
      );

      expect(plan.closedBucketIds, [bucketId]);
      expect(plan.openBucketIds, isEmpty);
      expect(plan.networkBucketIds, isEmpty);
    });

    test('filterForBucket keeps the full range filter', () {
      final filter = ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3),
      );
      final bucketId = CalendarBucketClosure.periodRangeBucketId(
        start: filter.dataVendaInicio,
        end: filter.dataVendaFim,
      );

      final bucketFilter = strategy.filterForBucket(
        rangeFilter: filter,
        bucketId: bucketId,
      );

      expect(bucketFilter.dataVendaInicio, filter.dataVendaInicio);
      expect(bucketFilter.dataVendaFim, filter.dataVendaFim);
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
