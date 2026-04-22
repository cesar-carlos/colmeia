import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_repository.dart';

/// Loads one page of the product sales summary. [ResumoProdutoVendaFilter]
/// carries **data inicial / final** de `DataVenda`, `origem`, paginação,
/// `sortBy` / `sortDirection` da métrica no `ROW_NUMBER`, e limites validados
/// no domínio.
class LoadResumoProdutoVendaPageUseCase {
  LoadResumoProdutoVendaPageUseCase(this._repository);

  final ResumoProdutoVendaRepository _repository;

  Future<AppResult<ResumoProdutoVendaPageResult>> call({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaFilter filter,
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
