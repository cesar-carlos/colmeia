import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// Catalog options used by product-related filters in multiple reports.
// ignore: one_member_abstracts
abstract interface class GrupoProdutoOptionsRepository {
  /// `searchTerm` is the preferred text filter for large dropdown autocompletes.
  ///
  /// `nomeGrupoProduto` is kept for backward compatibility with existing call
  /// sites and will be removed after migration.
  Future<AppResult<List<GrupoProdutoOption>>> loadAll({
    required String userId,
    required String agentId,
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    @Deprecated('Use searchTerm instead.') String? nomeGrupoProduto,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  });
}
