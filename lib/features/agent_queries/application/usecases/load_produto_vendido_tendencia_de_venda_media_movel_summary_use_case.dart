import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';

/// Loads moving-average trend summary rows grouped by classification.
class LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase {
  LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase(this._repository);

  final ProdutoVendidoTendenciaDeVendaMediaMovelRepository _repository;

  Future<AppResult<List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>>>
  call({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaMediaMovelFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.loadSummary(
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
