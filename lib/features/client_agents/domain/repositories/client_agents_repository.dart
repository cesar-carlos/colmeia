import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
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

  /// Network-only probe: linked vs not linked (`404`). Does not fall back to
  /// stale cached detail on 404.
  Future<AppResult<ClientApprovedAgentProbeOutcome>> probeApprovedAgentLink({
    required String userId,
    required String agentId,
  });

  /// Drops local `requestAccess` actions in `queued` or `failed` for [agentIds].
  Future<AppResult<Unit>> discardQueuedRequestAccessForAgents({
    required String userId,
    required Set<String> agentIds,
  });

  Future<AppResult<PaginatedResult<ClientAgentAccessRequest>>>
  loadAccessRequests({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  });

  Future<AppResult<Unit>> retryClientAccessRequest({
    required String userId,
    required String requestId,
  });

  Future<AppResult<List<ClientAgent>>> loadManagedAgents({
    required String userId,
  });

  Future<AppResult<List<OwnerClientAccessRequest>>> loadOwnerAccessRequests({
    required String userId,
  });

  Future<AppResult<Unit>> approveOwnerAccessRequest({
    required String userId,
    required String requestId,
  });

  Future<AppResult<Unit>> rejectOwnerAccessRequest({
    required String userId,
    required String requestId,
  });

  Future<AppResult<List<OwnerApprovedClient>>> loadOwnerApprovedClients({
    required String userId,
    required String agentId,
  });

  Future<AppResult<Unit>> revokeOwnerClientAccess({
    required String userId,
    required String agentId,
    required String clientId,
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
