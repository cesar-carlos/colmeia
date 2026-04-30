import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';

// Single report entry point; batch/cancel can extend later if needed.
abstract interface class ProdutoVendidoTendenciaDeVendaRepository {
  Future<AppResult<List<ProdutoVendidoTendenciaDeVendaRow>>> loadAll({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });

  Future<AppResult<List<ProdutoVendidoTendenciaDeVendaSummaryRow>>>
  loadSummary({
    required String userId,
    required String agentId,
    required ProdutoVendidoTendenciaDeVendaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
