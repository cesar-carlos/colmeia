import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';

// Single entry point for now; batch/cancel may extend this interface later.
// ignore: one_member_abstracts
abstract interface class ResumoProdutoVendaLucratividadeMensalRepository {
  Future<AppResult<List<ResumoProdutoVendaLucratividadeMensalRow>>> loadAll({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaLucratividadeMensalFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
