import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_resumo_fornecedor_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// ignore: one_member_abstracts — mirrors the other agent SQL repository ports.
abstract interface class NotasEntradaResumoFornecedorRepository {
  Future<AppResult<NotasEntradaResumoFornecedorPageResult>> loadPage({
    required String userId,
    required String agentId,
    required NotasEntradaFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  });
}
