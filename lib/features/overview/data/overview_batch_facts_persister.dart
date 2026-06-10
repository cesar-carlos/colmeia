import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_parcelas_mensal_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/cache/consolidation_catalog.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';

/// Writes closed Hive fact buckets from overview section-batch rows so sales
/// screens can reuse [CachingResumo*] repositories without a second hub round.
final class OverviewBatchFactsPersister {
  OverviewBatchFactsPersister({
    required AgentQueryFactsStore factsStore,
    ResumoTotalDiarioVendasCacheStrategy dailyStrategy =
        const ResumoTotalDiarioVendasCacheStrategy(),
    ResumoParcelasMensalCacheStrategy monthlyStrategy =
        const ResumoParcelasMensalCacheStrategy(),
    DateTime Function()? clock,
  }) : _factsStore = factsStore,
       _dailyStrategy = dailyStrategy,
       _monthlyStrategy = monthlyStrategy,
       _clock = clock ?? DateTime.now;

  final AgentQueryFactsStore _factsStore;
  final ResumoTotalDiarioVendasCacheStrategy _dailyStrategy;
  final ResumoParcelasMensalCacheStrategy _monthlyStrategy;
  final DateTime Function() _clock;

  Future<void> persistDailyRows({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    required List<ResumoTotalDiarioVendasRow> rows,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    if (cachePolicy == AgentQueryLoadPolicy.forceRefresh || rows.isEmpty) {
      return;
    }
    final clock = _clock();
    final plan = _dailyStrategy.planBuckets(
      filter: filter,
      clock: clock,
      policy: cachePolicy,
    );
    if (!ConsolidationCatalog.mayPersist(
      factKind: _dailyStrategy.factKind,
      writer: _dailyStrategy.queryKey,
    )) {
      return;
    }
    for (final bucketId in plan.closedBucketIds) {
      final bucketFilter = _dailyStrategy.filterForBucket(
        rangeFilter: filter,
        bucketId: bucketId,
      );
      final bucketRows = rows
          .where(
            (row) =>
                _isSameLocalDay(row.dataVenda, bucketFilter.dataVendaInicio),
          )
          .toList(growable: false);
      if (bucketRows.isEmpty) {
        continue;
      }
      await _factsStore.writePayload(
        storageKey: _dailyStrategy.storageKey(
          userId: userId,
          agentId: agentId,
          bucketId: bucketId,
          rangeFilter: filter,
        ),
        payload: _dailyStrategy.encodePayload(bucketRows),
        schemaVersion: _dailyStrategy.schemaVersion,
      );
    }
  }

  Future<void> persistMonthlyRows({
    required String userId,
    required String agentId,
    required ResumoParcelasMensalFilter filter,
    required List<ResumoParcelasMensalRow> rows,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    if (cachePolicy == AgentQueryLoadPolicy.forceRefresh || rows.isEmpty) {
      return;
    }
    final clock = _clock();
    final plan = _monthlyStrategy.planBuckets(
      filter: filter,
      clock: clock,
      policy: cachePolicy,
    );
    if (!ConsolidationCatalog.mayPersist(
      factKind: _monthlyStrategy.factKind,
      writer: _monthlyStrategy.queryKey,
    )) {
      return;
    }
    for (final bucketId in plan.closedBucketIds) {
      final bucketFilter = _monthlyStrategy.filterForBucket(
        rangeFilter: filter,
        bucketId: bucketId,
      );
      final bucketRows = rows
          .where(
            (row) =>
                row.ano == bucketFilter.dataVendaInicio.year &&
                row.mes == bucketFilter.dataVendaInicio.month,
          )
          .toList(growable: false);
      if (bucketRows.isEmpty) {
        continue;
      }
      await _factsStore.writePayload(
        storageKey: _monthlyStrategy.storageKey(
          userId: userId,
          agentId: agentId,
          bucketId: bucketId,
          rangeFilter: filter,
        ),
        payload: _monthlyStrategy.encodePayload(bucketRows),
        schemaVersion: _monthlyStrategy.schemaVersion,
      );
    }
  }

  static bool _isSameLocalDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
