import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_repository.dart';

/// Loads trend summary rows grouped by classification.
class LoadProdutoVendidoTendenciaDeVendaSummaryUseCase {
  LoadProdutoVendidoTendenciaDeVendaSummaryUseCase(this._repository);

  final ProdutoVendidoTendenciaDeVendaRepository _repository;

  Future<AppResult<List<ProdutoVendidoTendenciaDeVendaSummaryRow>>> call({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaFilter filter,
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
