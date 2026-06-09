import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_marca_produto_options_batch.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/grupo_marca_produto_options_repository.dart';

class LoadGrupoMarcaProdutoOptionsUseCase {
  LoadGrupoMarcaProdutoOptionsUseCase(this._repository);

  final GrupoMarcaProdutoOptionsRepository _repository;

  Future<AppResult<GrupoMarcaProdutoOptionsBatch>> call({
    required String userId,
    required String agentId,
    int page = 1,
    int pageSize = 20,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _repository.loadGrupoAndMarcaOptions(
      userId: userId,
      agentId: agentId,
      page: page,
      pageSize: pageSize,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
    );
  }
}
