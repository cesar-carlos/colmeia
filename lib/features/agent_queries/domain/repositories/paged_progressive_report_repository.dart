import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

// Loads a complete filtered catalog as validated numbered pages.
// ignore: one_member_abstracts
abstract interface class PagedProgressiveReportRepository<Filter, Row> {
  Stream<AppResult<AgentQueryProgress<Row>>> loadPagesProgressively({
    required String userId,
    required String agentId,
    required Filter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    bool emitPartialResults = true,
  });
}
