import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_repository.dart';

/// Loads the period product profitability summary for a single agent.
///
/// [ResumoProdutoVendaLucratividadeFilter] carries `dataVendaInicio`,
/// `dataVendaFim`, and `origem`; the result is one row per `CodEmpresa/CodFilial`
/// ordered by empresa and filial (fixed — no pagination).
class LoadResumoProdutoVendaLucratividadeUseCase {
  LoadResumoProdutoVendaLucratividadeUseCase(this._repository);

  final ResumoProdutoVendaLucratividadeRepository _repository;

  Future<AppResult<List<ResumoProdutoVendaLucratividadeRow>>> call({
    required String userId,
    required String agentId,
    required ResumoProdutoVendaLucratividadeFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.loadAll(
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
