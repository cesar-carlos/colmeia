import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_produto_rank_lucro_repository.dart';

/// Loads the top product profitability ranking (`TOP 15`) for a single agent.
///
/// [ProdutoVendidoProdutoRankLucroFilter] carries `dataVendaInicio`,
/// `dataVendaFim`, `origem`, and sort options (`sortBy`, `sortDirection`).
class LoadProdutoVendidoProdutoRankLucroUseCase {
  LoadProdutoVendidoProdutoRankLucroUseCase(this._repository);

  final ProdutoVendidoProdutoRankLucroRepository _repository;

  Future<AppResult<List<ProdutoVendidoProdutoRankLucroRow>>> call({
    required String userId,
    required String agentId,
    required ProdutoVendidoProdutoRankLucroFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.loadAll(
      userId: userId,
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }
}
