import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/fornecedor_options_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/fornecedor_options_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// Paginated fornecedor catalog from agent SQL (DI + tests mirror other query
// repos).
// ignore: one_member_abstracts
abstract interface class FornecedorOptionsRepository {
  Future<AppResult<FornecedorOptionsPageResult>> loadPage({
    required String userId,
    required String agentId,
    required FornecedorOptionsFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  });
}
