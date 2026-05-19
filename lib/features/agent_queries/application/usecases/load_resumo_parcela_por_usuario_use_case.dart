import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_por_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_por_usuario_repository.dart';

class LoadResumoParcelaPorUsuarioUseCase {
  LoadResumoParcelaPorUsuarioUseCase(this._repository);

  final ResumoParcelaPorUsuarioRepository _repository;

  Future<AppResult<List<ResumoParcelaPorUsuarioRow>>> call({
    required String userId,
    required String agentId,
    required ResumoParcelaPorUsuarioFilter filter,
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
