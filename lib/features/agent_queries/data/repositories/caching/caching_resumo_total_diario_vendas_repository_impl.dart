import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/agent_query_facts_bucket_batch_support.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/agent_query_facts_bucket_batch_supports.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/base_cached_agent_query_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_repository.dart';

final class CachingResumoTotalDiarioVendasRepositoryImpl
    extends
        BaseCachedAgentQueryRepository<
          ResumoTotalDiarioVendasFilter,
          ResumoTotalDiarioVendasRow
        >
    implements ResumoTotalDiarioVendasRepository {
  CachingResumoTotalDiarioVendasRepositoryImpl({
    required ResumoTotalDiarioVendasRepository delegate,
    required super.factsStore,
    super.agentQueriesRepository,
    AgentQueryFactsBucketBatchSupport<
      ResumoTotalDiarioVendasFilter,
      ResumoTotalDiarioVendasRow
    >?
    bucketBatchSupport,
    ResumoTotalDiarioVendasCacheStrategy super.strategy =
        const ResumoTotalDiarioVendasCacheStrategy(),
    super.clock,
    super.bucketLoadConcurrency,
    super.useExecuteBatchForBuckets,
  }) : super(
         bucketBatchSupport:
             bucketBatchSupport ??
             const ResumoTotalDiarioVendasFactsBucketBatchSupport(),
         delegateLoad:
             ({
               required userId,
               required agentId,
               required filter,
               clientToken,
               bridgeTimeoutMs,
               hubPresenceOnlineAgentIdsSnapshot,
               hubConnectedFromApprovedCatalogRow,
               cancelScope,
               cachePolicy = AgentQueryLoadPolicy.defaultLoad,
             }) => delegate.load(
               userId: userId,
               agentId: agentId,
               filter: filter,
               clientToken: clientToken,
               bridgeTimeoutMs: bridgeTimeoutMs,
               hubPresenceOnlineAgentIdsSnapshot:
                   hubPresenceOnlineAgentIdsSnapshot,
               hubConnectedFromApprovedCatalogRow:
                   hubConnectedFromApprovedCatalogRow,
               cancelScope: cancelScope,
               cachePolicy: cachePolicy,
             ),
       );

  @override
  Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) {
    return loadWithCache(
      userId: userId,
      agentId: agentId,
      filter: filter,
      cachePolicy: cachePolicy,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
    );
  }
}
