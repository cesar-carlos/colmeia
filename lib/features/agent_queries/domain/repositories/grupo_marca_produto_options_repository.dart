import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_marca_produto_options_batch.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// ignore: one_member_abstracts — single batch load mirrors other agent SQL repository ports.
abstract interface class GrupoMarcaProdutoOptionsRepository {
  Future<AppResult<GrupoMarcaProdutoOptionsBatch>> loadGrupoAndMarcaOptions({
    required String userId,
    required String agentId,
    int page = 1,
    int pageSize = 20,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  });
}
