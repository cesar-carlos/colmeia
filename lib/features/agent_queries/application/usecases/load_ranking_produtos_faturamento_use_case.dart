import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_load_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/ranking_produtos_faturamento_repository.dart';

/// Loads the product billing ranking for a single agent.
///
/// Does not reorder or transform rows — order matches the SQL result
/// (DIVERSOS last within each branch when present).
class LoadRankingProdutosFaturamentoUseCase {
  LoadRankingProdutosFaturamentoUseCase(this._repository);

  final RankingProdutosFaturamentoRepository _repository;

  Future<AppResult<RankingProdutosFaturamentoLoadResult>> call({
    required String userId,
    required String agentId,
    required RankingProdutosFaturamentoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _repository.load(
      userId: userId,
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
    );
  }
}
