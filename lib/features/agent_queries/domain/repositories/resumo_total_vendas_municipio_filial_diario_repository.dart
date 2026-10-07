import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// ignore: one_member_abstracts — single `load` mirrors other agent SQL repository ports.
abstract interface class ResumoTotalVendasMunicipioFilialDiarioRepository {
  Future<AppResult<List<ResumoTotalVendasMunicipioFilialDiarioRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalVendasMunicipioFilialDiarioFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    AgentQueriesCancelScope? cancelScope,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
