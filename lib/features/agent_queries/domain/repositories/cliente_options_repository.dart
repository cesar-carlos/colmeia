import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cliente_options_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cliente_options_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// Paginated cliente catalog from agent SQL (DI + tests mirror other query
// repos).
// ignore: one_member_abstracts
abstract interface class ClienteOptionsRepository {
  Future<AppResult<ClienteOptionsPageResult>> loadPage({
    required String userId,
    required String agentId,
    required ClienteOptionsFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  });
}
