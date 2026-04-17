import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';

// Query-specific repository entry point; more report methods may be added here.
// ignore: one_member_abstracts
abstract interface class ResumoParcelasDiaSemanaUsuarioRepository {
  Future<AppResult<List<ResumoParcelasDiaSemanaUsuarioRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelasDiaSemanaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
