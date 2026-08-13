import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';

/// Loads one page of the product-margin catalog. [MargemProdutoFilter]
/// carries company/branch, pagination, and `sortBy` / `sortDirection` of the
/// metric in `ROW_NUMBER`, with limits validated in the domain.
class LoadMargemProdutoPageUseCase {
  LoadMargemProdutoPageUseCase(this._repository);

  final MargemProdutoRepository _repository;

  Future<AppResult<MargemProdutoPageResult>> call({
    required String userId,
    required String agentId,
    required MargemProdutoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.loadPage(
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
