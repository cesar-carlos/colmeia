import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_row.dart';

// Ignored because this is an architectural port for a specific query use-case.
// ignore: one_member_abstracts
abstract interface class ProdutoVendidoProdutoRankLucroRepository {
  Future<AppResult<List<ProdutoVendidoProdutoRankLucroRow>>> loadAll({
    required String userId,
    required String agentId,
    required ProdutoVendidoProdutoRankLucroFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
