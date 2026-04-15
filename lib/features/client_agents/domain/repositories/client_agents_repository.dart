import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:result_dart/result_dart.dart';

abstract interface class ClientAgentsRepository {
  Future<AppResult<PaginatedResult<ClientAgentCatalogItem>>> loadCatalog({
    required String userId,
    required PaginatedQuery query,
    String? search,
  });

  Future<AppResult<ClientAgentCatalogItem>> loadCatalogAgentById({
    required String userId,
    required String agentId,
  });

  Future<AppResult<ClientAgent>> updateCatalogAgentProfile({
    required String userId,
    required String agentId,
    required AgentProfileUpdateRequest request,
  });

  Future<AppResult<PaginatedResult<ClientAgent>>> loadApprovedAgents({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
    bool includeOnlineStatus = true,
    bool refresh = false,
  });

  Future<AppResult<ClientAgent>> loadApprovedAgentById({
    required String userId,
    required String agentId,
  });

  Future<AppResult<PaginatedResult<ClientAgentAccessRequest>>>
  loadAccessRequests({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  });

  Future<AppResult<ClientAccessStatusSnapshot>> loadClientAccessStatus({
    required String token,
  });

  Future<AppResult<List<PendingAgentAction>>> readPendingActions({
    required String userId,
  });

  Future<AppResult<Unit>> queueRequestAccess({
    required String userId,
    required Set<String> agentIds,
  });

  Future<AppResult<Unit>> queueRemoveAccess({
    required String userId,
    required Set<String> agentIds,
  });

  Future<AppResult<SyncPendingAgentActionsResult>> syncPendingActions({
    required String userId,
  });

  /// Agent ids currently reported as connected (hub/cache), or `null` when
  /// presence could not be resolved.
  Future<Set<String>?> loadOnlineAgentIds({required String userId});
}
