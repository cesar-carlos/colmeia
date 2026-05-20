import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';

class LoadProdutoVendidoTendenciaDeVendaScreenUseCase {
  LoadProdutoVendidoTendenciaDeVendaScreenUseCase(this._repository);

  final ProdutoVendidoTendenciaDeVendaRepository _repository;

  Future<AppResult<ProdutoVendidoTendenciaDeVendaScreenData>> call({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaFilter pageFilter,
    required ProdutoVendidoTendenciaDeVendaFilter summaryFilter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.loadPageAndSummary(
      userId: userId,
      agentId: agentId,
      pageFilter: pageFilter,
      summaryFilter: summaryFilter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }
}
