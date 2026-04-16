import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

Never _notUsed(String name) {
  throw UnsupportedError(
    'E2eStubClientAgentsForAgentQueries.$name is not used in agent-query e2e',
  );
}

/// Minimal `ClientAgentsRepository` so `AgentQueryTargetResolver` can build
/// targets without the full client-agents stack (Hive, cache, etc.).
final class E2eStubClientAgentsRepository implements ClientAgentsRepository {
  @override
  Future<AppResult<PaginatedResult<ClientAgentCatalogItem>>> loadCatalog({
    required String userId,
    required PaginatedQuery query,
    String? search,
  }) async {
    _notUsed('loadCatalog');
  }

  @override
  Future<AppResult<ClientAgentCatalogItem>> loadCatalogAgentById({
    required String userId,
    required String agentId,
  }) async {
    _notUsed('loadCatalogAgentById');
  }

  @override
  Future<AppResult<ClientAgent>> updateCatalogAgentProfile({
    required String userId,
    required String agentId,
    required AgentProfileUpdateRequest request,
  }) async {
    _notUsed('updateCatalogAgentProfile');
  }

  @override
  Future<AppResult<PaginatedResult<ClientAgent>>> loadApprovedAgents({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
    bool includeOnlineStatus = true,
    bool refresh = false,
  }) async {
    final agentId = AppEnvironment.e2eAgentId;
    if (agentId.isEmpty || query.page != 1) {
      return Success<PaginatedResult<ClientAgent>, AppFailure>(
        PaginatedResult<ClientAgent>(
          items: const <ClientAgent>[],
          count: 0,
          total: 0,
          page: query.page,
          pageSize: query.pageSize,
        ),
      );
    }

    final stamp = DateTime.utc(2020);
    final agent = ClientAgent(
      agentId: agentId,
      name: 'E2E stub approved agent',
      catalogStatus: AgentCatalogStatus.active,
      connectionStatus: AgentConnectionStatus.unknown,
      createdAt: stamp,
      updatedAt: stamp,
    );
    return Success<PaginatedResult<ClientAgent>, AppFailure>(
      PaginatedResult<ClientAgent>(
        items: <ClientAgent>[agent],
        count: 1,
        total: 1,
        page: query.page,
        pageSize: query.pageSize,
      ),
    );
  }

  @override
  Future<AppResult<ClientAgent>> loadApprovedAgentById({
    required String userId,
    required String agentId,
  }) async {
    _notUsed('loadApprovedAgentById');
  }

  @override
  Future<AppResult<ClientApprovedAgentProbeOutcome>> probeApprovedAgentLink({
    required String userId,
    required String agentId,
  }) async {
    _notUsed('probeApprovedAgentLink');
  }

  @override
  Future<AppResult<Unit>> discardQueuedRequestAccessForAgents({
    required String userId,
    required Set<String> agentIds,
  }) async {
    _notUsed('discardQueuedRequestAccessForAgents');
  }

  @override
  Future<AppResult<PaginatedResult<ClientAgentAccessRequest>>>
  loadAccessRequests({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) async {
    _notUsed('loadAccessRequests');
  }

  @override
  Future<AppResult<ClientAccessStatusSnapshot>> loadClientAccessStatus({
    required String token,
  }) async {
    _notUsed('loadClientAccessStatus');
  }

  @override
  Future<AppResult<List<PendingAgentAction>>> readPendingActions({
    required String userId,
  }) async {
    _notUsed('readPendingActions');
  }

  @override
  Future<AppResult<Unit>> queueRequestAccess({
    required String userId,
    required Set<String> agentIds,
  }) async {
    _notUsed('queueRequestAccess');
  }

  @override
  Future<AppResult<Unit>> queueRemoveAccess({
    required String userId,
    required Set<String> agentIds,
  }) async {
    _notUsed('queueRemoveAccess');
  }

  @override
  Future<AppResult<SyncPendingAgentActionsResult>> syncPendingActions({
    required String userId,
  }) async {
    _notUsed('syncPendingActions');
  }

  @override
  Future<Set<String>?> loadOnlineAgentIds({required String userId}) async {
    // Null snapshot disables hub-presence gating so e2e SQL runs without Hive
    // online-agent cache.
    return null;
  }
}

/// Supplies the bridge `client_token` for `AppEnvironment.e2eAgentId` only.
final class E2eStubAgentClientTokenReader implements AgentClientTokenReader {
  @override
  Future<Map<String, String>> readMany({
    required String userId,
    required Iterable<String> agentIds,
  }) async {
    final token = AppEnvironment.e2eClientToken;
    final configuredId = AppEnvironment.e2eAgentId;
    if (token.isEmpty || configuredId.isEmpty) {
      return <String, String>{};
    }
    final out = <String, String>{};
    for (final id in agentIds) {
      if (id == configuredId) {
        out[id] = token;
      }
    }
    return out;
  }
}
