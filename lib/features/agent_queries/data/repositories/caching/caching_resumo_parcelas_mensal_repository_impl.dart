import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_parcelas_mensal_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/agent_query_facts_bucket_batch_support.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/agent_query_facts_bucket_batch_supports.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/base_cached_agent_query_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_repository.dart';

final class CachingResumoParcelasMensalRepositoryImpl
    extends BaseCachedAgentQueryRepository<
      ResumoParcelasMensalFilter,
      ResumoParcelasMensalRow
    >
    implements ResumoParcelasMensalRepository {
  CachingResumoParcelasMensalRepositoryImpl({
    required ResumoParcelasMensalRepository delegate,
    required super.factsStore,
    super.agentQueriesRepository,
    AgentQueryFactsBucketBatchSupport<ResumoParcelasMensalFilter,
            ResumoParcelasMensalRow>?
        bucketBatchSupport,
    ResumoParcelasMensalCacheStrategy super.strategy =
        const ResumoParcelasMensalCacheStrategy(),
    super.clock,
  }) : super(
         bucketBatchSupport:
             bucketBatchSupport ??
             const ResumoParcelasMensalFactsBucketBatchSupport(),
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
             }) {
               return delegate.load(
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
               );
             },
       );

  @override
  Future<AppResult<List<ResumoParcelasMensalRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasMensalFilter filter,
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
