import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// ignore: one_member_abstracts — mirrors the other agent SQL repository ports.
abstract interface class NotasEntradaItensRepository {
  Future<AppResult<NotasEntradaItensResult>> load({
    required String userId,
    required String agentId,
    required NotasEntradaItensFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  });
}
