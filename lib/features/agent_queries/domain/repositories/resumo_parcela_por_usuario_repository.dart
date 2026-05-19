import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';

// ignore: one_member_abstracts, reason: Repository boundaries in this project use single-method contracts for DI and testing.
abstract interface class ResumoParcelaPorUsuarioRepository {
  Future<AppResult<List<ResumoParcelaPorUsuarioRow>>> load({
    required String userId,
    required String agentId,
    required ResumoParcelaPorUsuarioFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  });
}
