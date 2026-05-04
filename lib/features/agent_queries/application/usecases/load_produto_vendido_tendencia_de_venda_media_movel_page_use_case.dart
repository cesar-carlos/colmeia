import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';

/// Loads one page of moving-average product sales trend rows.
class LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase {
  LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase(this._repository);

  final ProdutoVendidoTendenciaDeVendaMediaMovelRepository _repository;

  Future<AppResult<ProdutoVendidoTendenciaDeVendaMediaMovelPageResult>> call({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaMediaMovelFilter filter,
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
