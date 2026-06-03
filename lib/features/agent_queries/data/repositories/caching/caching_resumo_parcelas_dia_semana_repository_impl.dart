import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_parcelas_dia_semana_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/base_cached_agent_query_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row_merger.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_repository.dart';
import 'package:result_dart/result_dart.dart';

final class CachingResumoParcelasDiaSemanaRepositoryImpl
    extends BaseCachedAgentQueryRepository<
      ResumoParcelasDiaSemanaFilter,
      ResumoParcelasDiaSemanaRow
    >
    implements ResumoParcelasDiaSemanaRepository {
  CachingResumoParcelasDiaSemanaRepositoryImpl({
    required ResumoParcelasDiaSemanaRepository delegate,
    required super.factsStore,
    ResumoParcelasDiaSemanaCacheStrategy super.strategy =
        const ResumoParcelasDiaSemanaCacheStrategy(),
    super.clock,
  }) : super(
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
  Future<AppResult<List<ResumoParcelasDiaSemanaRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasDiaSemanaFilter filter,
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
    return Success(ResumoParcelasDiaSemanaRowMerger.merge(rows));
  }
}
