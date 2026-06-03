import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_produto_venda_lucratividade_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/agent_query_facts_bucket_batch_support.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/agent_query_facts_bucket_batch_supports.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/base_cached_agent_query_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_repository.dart';
import 'package:result_dart/result_dart.dart';

final class CachingResumoProdutoVendaLucratividadeRepositoryImpl
    extends BaseCachedAgentQueryRepository<
      ResumoProdutoVendaLucratividadeFilter,
      ResumoProdutoVendaLucratividadeRow
    >
    implements ResumoProdutoVendaLucratividadeRepository {
  CachingResumoProdutoVendaLucratividadeRepositoryImpl({
    required ResumoProdutoVendaLucratividadeRepository delegate,
    required super.factsStore,
    AgentQueriesRepository? agentQueriesRepository,
    AgentQueryFactsBucketBatchSupport<ResumoProdutoVendaLucratividadeFilter,
            ResumoProdutoVendaLucratividadeRow>?
        bucketBatchSupport,
    ResumoProdutoVendaLucratividadeCacheStrategy super.strategy =
        const ResumoProdutoVendaLucratividadeCacheStrategy(),
    super.clock,
  }) : super(
         agentQueriesRepository: agentQueriesRepository,
         bucketBatchSupport:
             bucketBatchSupport ??
             const ResumoProdutoVendaLucratividadeFactsBucketBatchSupport(),
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
               return delegate.loadAll(
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
  Future<AppResult<List<ResumoProdutoVendaLucratividadeRow>>> loadAll({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaLucratividadeFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    final cached = await loadWithCache(
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
    final rows = cached.getOrNull();
    if (rows == null) {
      return Failure(cached.exceptionOrNull()!);
    }
    return Success(ResumoProdutoVendaLucratividadeRowMerger.merge(rows));
  }
}
