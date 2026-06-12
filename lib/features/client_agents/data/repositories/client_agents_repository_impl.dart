import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_access_requests_repository_impl.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agent_catalog_repository_impl.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_cache_support.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_approved_agents_repository_impl.dart';
import 'package:colmeia/features/client_agents/data/repositories/owner_agents_repository_impl.dart';
import 'package:colmeia/features/client_agents/data/sync/pending_client_agent_actions_synchronizer.dart';
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
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Facade composing the four bounded repository implementations. New code
/// should depend on the narrowest sub-interface; this type keeps existing
/// `ClientAgentsRepository` call sites unchanged.
class ClientAgentsRepositoryImpl implements ClientAgentsRepository {
  ClientAgentsRepositoryImpl({
    required ClientAgentsRemoteDataSource remoteDataSource,
    required ClientAgentsLocalDataSource localDataSource,
  }) : this._withCacheSupport(
         remoteDataSource: remoteDataSource,
         localDataSource: localDataSource,
         cacheSupport: ClientAgentsRepositoryCacheSupport(localDataSource),
       );

  ClientAgentsRepositoryImpl._withCacheSupport({
    required ClientAgentsRemoteDataSource remoteDataSource,
    required ClientAgentsLocalDataSource localDataSource,
    required ClientAgentsRepositoryCacheSupport cacheSupport,
  }) : _catalog = ClientAgentCatalogRepositoryImpl(
         remoteDataSource: remoteDataSource,
         localDataSource: localDataSource,
         cacheSupport: cacheSupport,
       ),
       _approved = ClientApprovedAgentsRepositoryImpl(
         remoteDataSource: remoteDataSource,
         localDataSource: localDataSource,
         cacheSupport: cacheSupport,
       ),
       _access = ClientAccessRequestsRepositoryImpl(
         remoteDataSource: remoteDataSource,
         localDataSource: localDataSource,
         cacheSupport: cacheSupport,
         synchronizer: PendingClientAgentActionsSynchronizer(
           remoteDataSource: remoteDataSource,
           localDataSource: localDataSource,
         ),
       ),
       _owner = OwnerAgentsRepositoryImpl(
         remoteDataSource: remoteDataSource,
         localDataSource: localDataSource,
         cacheSupport: cacheSupport,
       );

  final ClientAgentCatalogRepositoryImpl _catalog;
  final ClientApprovedAgentsRepositoryImpl _approved;
  final ClientAccessRequestsRepositoryImpl _access;
  final OwnerAgentsRepositoryImpl _owner;

  @override
  Future<AppResult<PaginatedResult<ClientAgentCatalogItem>>> loadCatalog({
    required String userId,
    required PaginatedQuery query,
    String? search,
  }) => _catalog.loadCatalog(userId: userId, query: query, search: search);

  @override
  Future<AppResult<ClientAgentCatalogItem>> loadCatalogAgentById({
    required String userId,
    required String agentId,
  }) => _catalog.loadCatalogAgentById(userId: userId, agentId: agentId);

  @override
  Future<AppResult<ClientAgent>> updateCatalogAgentProfile({
    required String userId,
    required String agentId,
    required AgentProfileUpdateRequest request,
  }) => _catalog.updateCatalogAgentProfile(
    userId: userId,
    agentId: agentId,
    request: request,
  );

  @override
  Future<AppResult<PaginatedResult<ClientAgent>>> loadApprovedAgents({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
    bool includeOnlineStatus = true,
    bool refresh = false,
  }) => _approved.loadApprovedAgents(
    userId: userId,
    query: query,
    search: search,
    status: status,
    includeOnlineStatus: includeOnlineStatus,
    refresh: refresh,
  );

  @override
  Future<AppResult<ClientAgent>> loadApprovedAgentById({
    required String userId,
    required String agentId,
  }) => _approved.loadApprovedAgentById(userId: userId, agentId: agentId);

  @override
  Future<AppResult<ClientApprovedAgentProbeOutcome>> probeApprovedAgentLink({
    required String userId,
    required String agentId,
  }) => _approved.probeApprovedAgentLink(userId: userId, agentId: agentId);

  @override
  Future<AppResult<Unit>> applyApprovedAgentProfileSnapshotLocally({
    required String userId,
    required String agentId,
    required AgentProfileSnapshot snapshot,
  }) => _approved.applyApprovedAgentProfileSnapshotLocally(
    userId: userId,
    agentId: agentId,
    snapshot: snapshot,
  );

  @override
  Future<Set<String>?> loadOnlineAgentIds({required String userId}) =>
      _approved.loadOnlineAgentIds(userId: userId);

  @override
  Future<AppResult<ClientAccessStatusSnapshot>> loadClientAccessStatus({
    required String token,
  }) => _access.loadClientAccessStatus(token: token);

  @override
  Future<AppResult<PaginatedResult<ClientAgentAccessRequest>>>
  loadAccessRequests({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) => _access.loadAccessRequests(
    userId: userId,
    query: query,
    search: search,
    status: status,
  );

  @override
  Future<AppResult<Unit>> retryClientAccessRequest({
    required String userId,
    required String requestId,
  }) => _access.retryClientAccessRequest(
    userId: userId,
    requestId: requestId,
  );

  @override
  Future<AppResult<Unit>> discardQueuedRequestAccessForAgents({
    required String userId,
    required Set<String> agentIds,
  }) => _access.discardQueuedRequestAccessForAgents(
    userId: userId,
    agentIds: agentIds,
  );

  @override
  Future<AppResult<List<PendingAgentAction>>> readPendingActions({
    required String userId,
  }) => _access.readPendingActions(userId: userId);

  @override
  Future<AppResult<Unit>> queueRequestAccess({
    required String userId,
    required Set<String> agentIds,
  }) => _access.queueRequestAccess(userId: userId, agentIds: agentIds);

  @override
  Future<AppResult<Unit>> queueRemoveAccess({
    required String userId,
    required Set<String> agentIds,
  }) => _access.queueRemoveAccess(userId: userId, agentIds: agentIds);

  @override
  Future<AppResult<SyncPendingAgentActionsResult>> syncPendingActions({
    required String userId,
  }) => _access.syncPendingActions(userId: userId);

  @override
  Future<AppResult<List<ClientAgent>>> loadManagedAgents({
    required String userId,
  }) => _owner.loadManagedAgents(userId: userId);

  @override
  Future<AppResult<List<OwnerClientAccessRequest>>> loadOwnerAccessRequests({
    required String userId,
  }) => _owner.loadOwnerAccessRequests(userId: userId);

  @override
  Future<AppResult<Unit>> approveOwnerAccessRequest({
    required String userId,
    required String requestId,
  }) => _owner.approveOwnerAccessRequest(
    userId: userId,
    requestId: requestId,
  );

  @override
  Future<AppResult<Unit>> rejectOwnerAccessRequest({
    required String userId,
    required String requestId,
  }) => _owner.rejectOwnerAccessRequest(
    userId: userId,
    requestId: requestId,
  );

  @override
  Future<AppResult<List<OwnerApprovedClient>>> loadOwnerApprovedClients({
    required String userId,
    required String agentId,
  }) => _owner.loadOwnerApprovedClients(userId: userId, agentId: agentId);

  @override
  Future<AppResult<Unit>> revokeOwnerClientAccess({
    required String userId,
    required String agentId,
    required String clientId,
  }) => _owner.revokeOwnerClientAccess(
    userId: userId,
    agentId: agentId,
    clientId: clientId,
  );
}
