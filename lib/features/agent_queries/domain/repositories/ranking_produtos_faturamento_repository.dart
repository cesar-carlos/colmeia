import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_load_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// ignore: one_member_abstracts — single `load` mirrors other agent SQL repository ports.
abstract interface class RankingProdutosFaturamentoRepository {
  Future<AppResult<RankingProdutosFaturamentoLoadResult>> load({
    required String userId,
    required String agentId,
    required RankingProdutosFaturamentoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  });
}
