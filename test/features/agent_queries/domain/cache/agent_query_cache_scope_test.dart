import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_parcelas_mensal_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_cache_scope.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentQueryCacheScope', () {
    test('overview defaults produce stable periodo scope', () {
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 4),
        dataVendaFim: DateTime(2026, 4, 30),
      );
      expect(AgentQueryCacheScope.dailyScope(filter), 'FrenteLoja|S|N');
      expect(
        AgentQueryCacheScope.dailyScope(filter),
        AgentQueryCacheScope.dailyScope(
          ResumoTotalDiarioVendasFilter(
            dataVendaInicio: DateTime(2026),
            dataVendaFim: DateTime(2026, 12, 31),
          ),
        ),
      );
    });

    test('mensal optional dimensions change storage key', () {
      const strategy = ResumoParcelasMensalCacheStrategy();
      final base = ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 12, 31),
      );
      final withVendedor = ResumoParcelasMensalFilter(
        dataVendaInicio: base.dataVendaInicio,
        dataVendaFim: base.dataVendaFim,
        codVendedor: 42,
      );
      final keyBase = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-04',
        rangeFilter: base,
      );
      final keyScoped = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-04',
        rangeFilter: withVendedor,
      );
      expect(keyBase, isNot(keyScoped));
      expect(keyScoped, contains('v42'));
    });

    test('daily strategy keys differ only by scope when bucket matches', () {
      const strategy = ResumoTotalDiarioVendasCacheStrategy();
      final filterA = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 30),
        preVenda: 'S',
      );
      final filterB = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 30),
      );
      final keyA = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-06-01',
        rangeFilter: filterA,
      );
      final keyB = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-06-01',
        rangeFilter: filterB,
      );
      expect(keyA, isNot(keyB));
    });
  });
}
