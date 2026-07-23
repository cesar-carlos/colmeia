import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strategy = ResumoTotalDiarioVendasCacheStrategy();

  group('ResumoTotalDiarioVendasCacheStrategy', () {
    test('planBuckets splits closed and open days', () {
      final clock = DateTime(2026, 6, 3);
      final filter = ResumoTotalDiarioVendasFilter(
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

    test('forceRefresh loads every bucket from network', () {
      final clock = DateTime(2026, 6, 3);
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 2),
      );

      final plan = strategy.planBuckets(
        filter: filter,
        clock: clock,
        policy: AgentQueryLoadPolicy.forceRefresh,
      );

      expect(plan.networkBucketIds, ['2026-06-01', '2026-06-02']);
    });

    test('selectRowsForBucket keeps rows for the target day only', () {
      final rows = <ResumoTotalDiarioVendasRow>[
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: DateTime(2026, 6),
          qtdVendas: 1,
          valorTotalDiarioVenda: 1,
        ),
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: DateTime(2026, 6, 2),
          qtdVendas: 2,
          valorTotalDiarioVenda: 2,
        ),
      ];
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 2),
      );

      final selected = strategy.selectRowsForBucket(
        rows: rows,
        bucketId: '2026-06-02',
        rangeFilter: filter,
      );

      expect(selected.single.qtdVendas, 2);
      expect(strategy.supportsRangeCoalesce, isTrue);
    });
  });
}
