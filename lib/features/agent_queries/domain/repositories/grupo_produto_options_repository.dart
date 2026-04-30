import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';

// Catalog options used by product-related filters in multiple reports.
// ignore: one_member_abstracts
abstract interface class GrupoProdutoOptionsRepository {
  Future<AppResult<List<GrupoProdutoOption>>> loadAll({
    required String userId,
    required String agentId,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
