import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_loaded_rows.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_vendas_municipio_filial_periodo_repository.dart';

class LoadResumoTotalVendasMunicipioFilialPeriodoUseCase {
  LoadResumoTotalVendasMunicipioFilialPeriodoUseCase(this._repository);

  final ResumoTotalVendasMunicipioFilialPeriodoRepository _repository;

  Future<
    AppResult<AgentQueryLoadedRows<ResumoTotalVendasMunicipioFilialPeriodoRow>>
  >
  call({
    required String userId,
    required String agentId,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.load(
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
