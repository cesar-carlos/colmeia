import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_parcelas_mensal_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';

/// Detects whether closed daily/monthly fact buckets are already on disk so
/// overview can omit those sections from SQL and load them via cached use
/// cases instead of a cold-start merged batch.
final class OverviewCachedFactsWarmthChecker {
  OverviewCachedFactsWarmthChecker({
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

  Future<bool> areDailyMonthlyFactsWarm({
    required String userId,
    required List<AgentQueryTarget> targets,
    required ResumoTotalDiarioVendasFilter dailyFilter,
    required ResumoParcelasMensalFilter monthlyFilter,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    if (cachePolicy != AgentQueryLoadPolicy.defaultLoad || targets.isEmpty) {
      return false;
    }

    final clock = _clock();
    final dailyPlan = _dailyStrategy.planBuckets(
      filter: dailyFilter,
      clock: clock,
      policy: cachePolicy,
    );
    final monthlyPlan = _monthlyStrategy.planBuckets(
      filter: monthlyFilter,
      clock: clock,
      policy: cachePolicy,
    );
    if (dailyPlan.closedBucketIds.isEmpty &&
        monthlyPlan.closedBucketIds.isEmpty) {
      return true;
    }

    for (final target in targets) {
      for (final bucketId in dailyPlan.closedBucketIds) {
        final key = _dailyStrategy.storageKey(
          userId: userId,
          agentId: target.agentId,
          bucketId: bucketId,
          rangeFilter: dailyFilter,
        );
        final payload = await _factsStore.readPayload(
          storageKey: key,
          expectedSchemaVersion: _dailyStrategy.schemaVersion,
        );
        if (payload == null || payload.isEmpty) {
          return false;
        }
      }
      for (final bucketId in monthlyPlan.closedBucketIds) {
        final key = _monthlyStrategy.storageKey(
          userId: userId,
          agentId: target.agentId,
          bucketId: bucketId,
          rangeFilter: monthlyFilter,
        );
        final payload = await _factsStore.readPayload(
          storageKey: key,
          expectedSchemaVersion: _monthlyStrategy.schemaVersion,
        );
        if (payload == null || payload.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }
}
