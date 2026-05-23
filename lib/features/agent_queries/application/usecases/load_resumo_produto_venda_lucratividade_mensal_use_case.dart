import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_mensal_repository.dart';

/// Loads the full monthly product profitability summary for a given period.
/// [ResumoProdutoVendaLucratividadeMensalFilter] carries `dataVendaInicio`,
/// `dataVendaFim`, and `origem`; the result is ordered by empresa, filial,
/// year, month (fixed — no pagination or sort options).
class LoadResumoProdutoVendaLucratividadeMensalUseCase {
  LoadResumoProdutoVendaLucratividadeMensalUseCase(this._repository);

  final ResumoProdutoVendaLucratividadeMensalRepository _repository;

  Future<AppResult<List<ResumoProdutoVendaLucratividadeMensalRow>>> call({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaLucratividadeMensalFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _repository.loadAll(
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
