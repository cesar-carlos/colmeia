import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_vendas_municipio_filial_periodo_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/base_cached_agent_query_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_repository.dart';
import 'package:result_dart/result_dart.dart';

final class CachingResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl
    extends BaseCachedAgentQueryRepository<
      ResumoTotalVendasMunicipioFilialPeriodoFilter,
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >
    implements ResumoTotalVendasMunicipioFilialPeriodoRepository {
  CachingResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl({
    required ResumoTotalVendasMunicipioFilialPeriodoRepository delegate,
    required super.factsStore,
    ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy super.strategy =
        const ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy(),
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
             }) async {
               final loaded = await delegate.load(
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
               final payload = loaded.getOrNull();
               if (payload != null) {
                 return Success(payload.rows);
               }
               return Failure(loaded.exceptionOrNull()!);
             },
       );

  @override
  Future<
    AppResult<AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>>
  >
  load({
    required String userId,
    required String agentId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
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
    if (rows != null) {
      return Success(
        AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>(
          rows: rows,
        ),
      );
    }
    return Failure(cached.exceptionOrNull()!);
  }
}
