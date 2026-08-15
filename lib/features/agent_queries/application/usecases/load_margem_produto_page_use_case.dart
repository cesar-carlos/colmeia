import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/margem_produto_repository.dart';

/// Loads one page of the product-margin catalog. [MargemProdutoFilter]
/// carries optional product-name contains search and pagination; company
/// and branch are fixed at `1`/`1`. SQL always numbers rows by
/// `NomeProduto ASC`, then `CodProduto ASC`.
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
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _repository.loadPage(
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
