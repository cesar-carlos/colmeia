import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// ignore: one_member_abstracts -- single entry point matches other SQL catalog repositories.
abstract interface class CadastroFilialRepository {
  Future<AppResult<CadastroFilialPageResult>> loadPage({
    required String userId,
    required String agentId,
    required CadastroFilialFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  });
}
