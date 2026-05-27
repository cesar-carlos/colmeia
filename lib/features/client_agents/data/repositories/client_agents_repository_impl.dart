import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/repository_error_mapping.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/hub_presence_synthesizer.dart';
import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_response_mappers.dart';
import 'package:colmeia/features/client_agents/data/sync/pending_client_agent_actions_synchronizer.dart';
import 'package:colmeia/features/client_agents/data/validation/client_agents_id_validators.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class ClientAgentsRepositoryImpl implements ClientAgentsRepository {
  ClientAgentsRepositoryImpl({
    required ClientAgentsRemoteDataSource remoteDataSource,
    required ClientAgentsLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _synchronizer = PendingClientAgentActionsSynchronizer(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );

  static const Duration _onlineStatusMaxAge = Duration(minutes: 1);

  /// When the hub cannot be reached, use cached online presence only if it is
  /// newer than this limit; otherwise treat presence as unknown.
  static const Duration _onlineStatusOfflineFallbackMaxAge = Duration(days: 7);
  static const PaginatedQuery _defaultRefreshQuery = PaginatedQuery(
    pageSize: kClientAgentsListPageSize,
  );

  final ClientAgentsRemoteDataSource _remoteDataSource;
  final ClientAgentsLocalDataSource _localDataSource;
  final PendingClientAgentActionsSynchronizer _synchronizer;

  @override
  Future<AppResult<PaginatedResult<ClientAgentCatalogItem>>> loadCatalog({
    required String userId,
    required PaginatedQuery query,
    String? search,
  }) {
    return withRepositoryErrorMapping<PaginatedResult<ClientAgentCatalogItem>>(
      action: () async {
        final remote = await _remoteDataSource.fetchCatalog(
          query: query,
          search: search,
        );
        await _localDataSource.saveCatalog(
          userId: userId,
          query: query,
          search: search,
          payload: remote,
        );
        await _persistHubPresenceCacheFromProfiles(
          userId: userId,
          profiles: remote.agents,
        );
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusMaxAge,
        );
        return mapClientAgentCatalogResponse(remote, onlineIds: onlineIds);
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readCatalog(
          userId: userId,
          query: query,
          search: search,
        );
        if (cached == null) {
          return null;
        }
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusOfflineFallbackMaxAge,
        );
        return mapClientAgentCatalogResponse(
          cached,
          onlineIds: onlineIds,
          isStaleCache: true,
        );
      },
      fallbackMessage: 'Unable to load agent catalog',
      fallbackUserMessage: 'Could not load the agent catalog.',
      context: <String, Object?>{
        'operation': 'loadClientAgentCatalog',
        'userId': userId,
        ClientAgentsFailureUiKey.field: ClientAgentsFailureUiKey.loadCatalog,
      },
    );
  }

  @override
  Future<AppResult<ClientAgentCatalogItem>> loadCatalogAgentById({
    required String userId,
    required String agentId,
  }) {
    final validation = requireAgentId<ClientAgentCatalogItem>(agentId);
    if (validation.failure != null) {
      return Future.value(validation.failure!);
    }
    final trimmed = validation.trimmed;
    return withRepositoryErrorMapping<ClientAgentCatalogItem>(
      action: () async {
        final remote = await _remoteDataSource.fetchCatalogAgentById(trimmed);
        await _localDataSource.saveCatalogAgentById(
          userId: userId,
          agentId: trimmed,
          payload: remote,
        );
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusMaxAge,
        );
        return ClientAgentCatalogItem(
          agent: mapClientAgentProfile(remote, onlineIds: onlineIds),
        );
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readCatalogAgentById(
          userId: userId,
          agentId: trimmed,
        );
        if (cached == null) {
          return null;
        }
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusOfflineFallbackMaxAge,
        );
        return ClientAgentCatalogItem(
          agent: mapClientAgentProfile(cached, onlineIds: onlineIds),
          isStaleCache: true,
        );
      },
      fallbackMessage: 'Unable to load catalog agent by id',
      fallbackUserMessage: 'Could not load catalog agent details.',
      context: <String, Object?>{
        'operation': 'loadCatalogAgentById',
        'userId': userId,
        'agentId': trimmed,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.loadCatalogAgentById,
      },
    );
  }

  @override
  Future<AppResult<ClientAgent>> updateCatalogAgentProfile({
    required String userId,
    required String agentId,
    required AgentProfileUpdateRequest request,
  }) async {
    final validation = requireAgentId<ClientAgent>(agentId);
    if (validation.failure != null) {
      return validation.failure!;
    }
    final trimmed = validation.trimmed;
    return withRepositoryErrorMappingNoCache<ClientAgent>(
      action: () async {
        final remote = await _remoteDataSource.patchAgentProfile(
          agentId: trimmed,
          body: request.toWireJson(),
          idempotencyKey: request.idempotencyKey,
        );
        await _localDataSource.saveCatalogAgentById(
          userId: userId,
          agentId: trimmed,
          payload: remote,
        );
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusMaxAge,
        );
        return mapClientAgentProfile(remote, onlineIds: onlineIds);
      },
      fallbackMessage: 'Unable to update catalog agent profile',
      fallbackUserMessage:
          'Could not update the agent profile on the server.',
      context: <String, Object?>{
        'operation': 'updateCatalogAgentProfile',
        'userId': userId,
        'agentId': trimmed,
      },
    );
  }

  @override
  Future<AppResult<Unit>> applyApprovedAgentProfileSnapshotLocally({
    required String userId,
    required String agentId,
    required AgentProfileSnapshot snapshot,
  }) async {
    final validation = requireAgentId<Unit>(agentId);
    if (validation.failure != null) {
      return validation.failure!;
    }
    final trimmedAgentId = validation.trimmed;
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        await _applySnapshotToCachedAgentDetail(
          userId: userId,
          agentId: trimmedAgentId,
          snapshot: snapshot,
        );
        await _applySnapshotToCachedApprovedAgents(
          userId: userId,
          agentId: trimmedAgentId,
          snapshot: snapshot,
        );
        return unit;
      },
      fallbackMessage: 'Unable to persist approved agent snapshot locally',
      fallbackUserMessage:
          'Could not keep the refreshed agent profile locally.',
      context: <String, Object?>{
        'operation': 'applyApprovedAgentProfileSnapshotLocally',
        'userId': userId,
        'agentId': trimmedAgentId,
      },
    );
  }

  @override
  Future<AppResult<ClientAccessStatusSnapshot>> loadClientAccessStatus({
    required String token,
  }) async {
    final validation = requireClientAccessToken<ClientAccessStatusSnapshot>(
      token,
    );
    if (validation.failure != null) {
      return validation.failure!;
    }
    final trimmed = validation.trimmed;
    return withRepositoryErrorMappingNoCache<ClientAccessStatusSnapshot>(
      action: () async {
        final remote = await _remoteDataSource.fetchClientAccessStatus(
          token: trimmed,
        );
        return remote.toEntity();
      },
      fallbackMessage: 'Unable to load client access status',
      fallbackUserMessage: 'Could not read access request status.',
      context: <String, Object?>{
        'operation': 'loadClientAccessStatus',
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.loadClientAccessStatus,
      },
    );
  }

  /// [includeOnlineStatus] avoids online-agent enrichment when false (faster;
  /// each agent reports [AgentConnectionStatus.unknown]).
  @override
  Future<AppResult<PaginatedResult<ClientAgent>>> loadApprovedAgents({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
    bool includeOnlineStatus = true,
    bool refresh = false,
  }) {
    return withRepositoryErrorMapping<PaginatedResult<ClientAgent>>(
      action: () async {
        final remote = await _remoteDataSource.fetchApprovedAgents(
          query: query,
          search: search,
          status: status,
          refresh: refresh,
        );
        await _localDataSource.saveApprovedAgents(
          userId: userId,
          query: query,
          search: search,
          status: status,
          payload: remote,
        );
        if (includeOnlineStatus) {
          await _persistHubPresenceCacheFromProfiles(
            userId: userId,
            profiles: remote.agents,
          );
        }
        final onlineIds = includeOnlineStatus
            ? await _readOnlineAgentIds(
                userId: userId,
                maxAge: _onlineStatusMaxAge,
              )
            : null;
        return mapClientApprovedAgentsResponse(remote, onlineIds: onlineIds);
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readApprovedAgents(
          userId: userId,
          query: query,
          search: search,
          status: status,
        );
        if (cached == null) {
          return null;
        }
        final onlineIds = includeOnlineStatus
            ? await _readOnlineAgentIds(
                userId: userId,
                maxAge: _onlineStatusOfflineFallbackMaxAge,
              )
            : null;
        return mapClientApprovedAgentsResponse(
          cached,
          onlineIds: onlineIds,
          isStaleCache: true,
        );
      },
      fallbackMessage: 'Unable to load approved client agents',
      fallbackUserMessage: 'Could not load approved agents for this account.',
      context: <String, Object?>{
        'operation': 'loadApprovedClientAgents',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.loadApprovedAgents,
      },
    );
  }

  @override
  Future<AppResult<ClientAgent>> loadApprovedAgentById({
    required String userId,
    required String agentId,
  }) {
    return withRepositoryErrorMapping<ClientAgent>(
      action: () async {
        final remote = await _remoteDataSource.fetchApprovedAgentById(agentId);
        await _localDataSource.saveApprovedAgentDetail(
          userId: userId,
          agentId: agentId,
          payload: remote,
        );
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusMaxAge,
        );
        return mapClientAgentProfile(remote.agent, onlineIds: onlineIds);
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readApprovedAgentDetail(
          userId: userId,
          agentId: agentId,
        );
        if (cached == null) {
          return null;
        }
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusOfflineFallbackMaxAge,
        );
        return mapClientAgentProfile(
          cached.agent,
          onlineIds: onlineIds,
          isStaleCache: true,
        );
      },
      fallbackMessage: 'Unable to load approved agent detail',
      fallbackUserMessage: 'Could not load agent details.',
      context: <String, Object?>{
        'operation': 'loadApprovedAgentById',
        'userId': userId,
        'agentId': agentId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.loadAgentDetail,
      },
    );
  }

  @override
  Future<AppResult<ClientApprovedAgentProbeOutcome>> probeApprovedAgentLink({
    required String userId,
    required String agentId,
  }) {
    return withRepositoryErrorMappingNoCache<ClientApprovedAgentProbeOutcome>(
      action: () async {
        final remote = await _remoteDataSource.fetchApprovedAgentDetailOrNull(
          agentId,
        );
        if (remote == null) {
          await _localDataSource.clearApprovedAgentDetail(
            userId: userId,
            agentId: agentId,
          );
          return const ClientApprovedAgentProbeOutcome.notLinked();
        }
        await _localDataSource.saveApprovedAgentDetail(
          userId: userId,
          agentId: agentId,
          payload: remote,
        );
        await _persistHubPresenceCacheFromProfiles(
          userId: userId,
          profiles: <ClientAgentProfileDto>[remote.agent],
        );
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusMaxAge,
        );
        return ClientApprovedAgentProbeOutcome.linked(
          mapClientAgentProfile(remote.agent, onlineIds: onlineIds),
        );
      },
      fallbackMessage: 'Unable to probe approved agent link',
      fallbackUserMessage: 'Could not verify agent link status.',
      context: <String, Object?>{
        'operation': 'probeApprovedAgentLink',
        'userId': userId,
        'agentId': agentId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.probeApprovedAgentLink,
      },
    );
  }

  @override
  Future<AppResult<Unit>> discardQueuedRequestAccessForAgents({
    required String userId,
    required Set<String> agentIds,
  }) {
    if (agentIds.isEmpty) {
      return Future.value(const Success<Unit, AppFailure>(unit));
    }
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        final actions = await _localDataSource.readPendingActions(
          userId: userId,
        );
        final updated = actions
            .where(
              (action) => !_shouldDiscardRequestAccessAction(action, agentIds),
            )
            .toList(growable: false);
        if (updated.length != actions.length) {
          await _localDataSource.savePendingActions(
            userId: userId,
            actions: updated,
          );
        }
        return unit;
      },
      fallbackMessage: 'Unable to discard queued request-access actions',
      fallbackUserMessage: 'Could not update local pending actions.',
      context: <String, Object?>{
        'operation': 'discardQueuedRequestAccessForAgents',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.readPendingActions,
      },
    );
  }

  bool _shouldDiscardRequestAccessAction(
    PendingAgentAction action,
    Set<String> agentIds,
  ) {
    if (action.type != PendingAgentActionType.requestAccess) {
      return false;
    }
    if (!agentIds.contains(action.agentId)) {
      return false;
    }
    return action.state == PendingAgentActionState.queued ||
        action.state == PendingAgentActionState.failed;
  }

  @override
  Future<AppResult<PaginatedResult<ClientAgentAccessRequest>>>
      loadAccessRequests({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) {
    return withRepositoryErrorMapping<
        PaginatedResult<ClientAgentAccessRequest>>(
      action: () async {
        final remote = await _remoteDataSource.fetchAccessRequests(
          query: query,
          search: search,
          status: status,
        );
        await _localDataSource.saveAccessRequests(
          userId: userId,
          query: query,
          search: search,
          status: status,
          payload: remote,
        );
        return mapClientAccessRequestsResponse(remote);
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readAccessRequests(
          userId: userId,
          query: query,
          search: search,
          status: status,
        );
        if (cached == null) {
          return null;
        }
        return mapClientAccessRequestsResponse(cached, isStaleCache: true);
      },
      fallbackMessage: 'Unable to load access requests',
      fallbackUserMessage: 'Could not load request history.',
      context: <String, Object?>{
        'operation': 'loadAccessRequests',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.loadAccessRequests,
      },
    );
  }

  @override
  Future<AppResult<Unit>> retryClientAccessRequest({
    required String userId,
    required String requestId,
  }) {
    final validation = requireRequestId<Unit>(requestId);
    if (validation.failure != null) {
      return Future.value(validation.failure!);
    }
    final trimmed = validation.trimmed;
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        await _remoteDataSource.retryAccessRequest(requestId: trimmed);
        return unit;
      },
      fallbackMessage: 'Unable to retry access request',
      fallbackUserMessage: 'Could not retry this access request.',
      context: <String, Object?>{
        'operation': 'retryClientAccessRequest',
        'userId': userId,
        'requestId': trimmed,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.retryClientAccessRequest,
      },
    );
  }

  @override
  Future<AppResult<List<ClientAgent>>> loadManagedAgents({
    required String userId,
  }) {
    return withRepositoryErrorMapping<List<ClientAgent>>(
      action: () async {
        final remote = await _remoteDataSource.fetchManagedAgents();
        await _localDataSource.saveManagedAgents(
          userId: userId,
          payload: remote,
        );
        await _persistHubPresenceCacheFromProfiles(
          userId: userId,
          profiles: remote.agents,
        );
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusMaxAge,
        );
        return remote.agents
            .map((agent) => mapClientAgentProfile(agent, onlineIds: onlineIds))
            .toList(growable: false);
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readManagedAgents(userId: userId);
        if (cached == null) {
          return null;
        }
        final onlineIds = await _readOnlineAgentIds(
          userId: userId,
          maxAge: _onlineStatusOfflineFallbackMaxAge,
        );
        return cached.agents
            .map(
              (agent) => mapClientAgentProfile(
                agent,
                onlineIds: onlineIds,
                isStaleCache: true,
              ),
            )
            .toList(growable: false);
      },
      fallbackMessage: 'Unable to load managed agents',
      fallbackUserMessage: 'Could not load managed agents.',
      context: <String, Object?>{
        'operation': 'loadManagedAgents',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.loadManagedAgents,
      },
    );
  }

  @override
  Future<AppResult<List<OwnerClientAccessRequest>>> loadOwnerAccessRequests({
    required String userId,
  }) {
    return withRepositoryErrorMapping<List<OwnerClientAccessRequest>>(
      action: () async {
        final remote = await _remoteDataSource.fetchOwnerAccessRequests();
        await _localDataSource.saveOwnerAccessRequests(
          userId: userId,
          payload: remote,
        );
        return mapOwnerAccessRequestsResponse(remote);
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readOwnerAccessRequests(
          userId: userId,
        );
        if (cached == null) {
          return null;
        }
        return mapOwnerAccessRequestsResponse(cached, isStaleCache: true);
      },
      fallbackMessage: 'Unable to load owner access requests',
      fallbackUserMessage: 'Could not load client access requests for review.',
      context: <String, Object?>{
        'operation': 'loadOwnerAccessRequests',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.loadOwnerAccessRequests,
      },
    );
  }

  @override
  Future<AppResult<Unit>> approveOwnerAccessRequest({
    required String userId,
    required String requestId,
  }) {
    return _performOwnerRequestMutation(
      userId: userId,
      requestId: requestId,
      operation: 'approveOwnerAccessRequest',
      uiKey: ClientAgentsFailureUiKey.approveOwnerAccessRequest,
      fallbackUserMessage: 'Could not approve this access request.',
      action: (trimmed) => _remoteDataSource.approveOwnerAccessRequest(
        requestId: trimmed,
      ),
    );
  }

  @override
  Future<AppResult<Unit>> rejectOwnerAccessRequest({
    required String userId,
    required String requestId,
  }) {
    return _performOwnerRequestMutation(
      userId: userId,
      requestId: requestId,
      operation: 'rejectOwnerAccessRequest',
      uiKey: ClientAgentsFailureUiKey.rejectOwnerAccessRequest,
      fallbackUserMessage: 'Could not reject this access request.',
      action: (trimmed) => _remoteDataSource.rejectOwnerAccessRequest(
        requestId: trimmed,
      ),
    );
  }

  @override
  Future<AppResult<List<OwnerApprovedClient>>> loadOwnerApprovedClients({
    required String userId,
    required String agentId,
  }) {
    final validation = requireAgentId<List<OwnerApprovedClient>>(agentId);
    if (validation.failure != null) {
      return Future.value(validation.failure!);
    }
    final trimmedAgentId = validation.trimmed;
    return withRepositoryErrorMapping<List<OwnerApprovedClient>>(
      action: () async {
        final remote = await _remoteDataSource
            .fetchApprovedClientsForManagedAgent(agentId: trimmedAgentId);
        await _localDataSource.saveOwnerApprovedClients(
          userId: userId,
          agentId: trimmedAgentId,
          payload: remote,
        );
        return mapOwnerApprovedClientsResponse(remote);
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readOwnerApprovedClients(
          userId: userId,
          agentId: trimmedAgentId,
        );
        if (cached == null) {
          return null;
        }
        return mapOwnerApprovedClientsResponse(cached, isStaleCache: true);
      },
      fallbackMessage: 'Unable to load approved clients for managed agent',
      fallbackUserMessage: 'Could not load approved clients for this agent.',
      context: <String, Object?>{
        'operation': 'loadOwnerApprovedClients',
        'userId': userId,
        'agentId': trimmedAgentId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.loadOwnerApprovedClients,
      },
    );
  }

  @override
  Future<AppResult<Unit>> revokeOwnerClientAccess({
    required String userId,
    required String agentId,
    required String clientId,
  }) {
    final agentValidation = requireAgentId<Unit>(agentId);
    if (agentValidation.failure != null) {
      return Future.value(agentValidation.failure!);
    }
    final clientValidation = requireNonEmptyId<Unit>(
      clientId,
      technicalMessage: 'Client id is empty',
      userMessage: 'Invalid identifier when revoking the access.',
    );
    if (clientValidation.failure != null) {
      return Future.value(clientValidation.failure!);
    }
    final trimmedAgentId = agentValidation.trimmed;
    final trimmedClientId = clientValidation.trimmed;
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        await _remoteDataSource.revokeManagedAgentClientAccess(
          agentId: trimmedAgentId,
          clientId: trimmedClientId,
        );
        return unit;
      },
      fallbackMessage: 'Unable to revoke owner client access',
      fallbackUserMessage: 'Could not revoke this client access.',
      context: <String, Object?>{
        'operation': 'revokeOwnerClientAccess',
        'userId': userId,
        'agentId': trimmedAgentId,
        'clientId': trimmedClientId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.revokeOwnerClientAccess,
      },
    );
  }

  @override
  Future<AppResult<List<PendingAgentAction>>> readPendingActions({
    required String userId,
  }) {
    return withRepositoryErrorMappingNoCache<List<PendingAgentAction>>(
      action: () => _localDataSource.readPendingActions(userId: userId),
      fallbackMessage: 'Unable to read pending actions',
      fallbackUserMessage: 'Could not load pending submissions to sync.',
      context: <String, Object?>{
        'operation': 'readPendingClientAgentActions',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.readPendingActions,
      },
    );
  }

  @override
  Future<AppResult<Unit>> queueRequestAccess({
    required String userId,
    required Set<String> agentIds,
  }) {
    return _queueActions(
      userId: userId,
      agentIds: agentIds,
      type: PendingAgentActionType.requestAccess,
      operation: 'queueRequestAccess',
      uiKey: ClientAgentsFailureUiKey.queueRequestAccess,
      fallbackMessage: 'Unable to queue request-access actions',
      fallbackUserMessage: 'Could not queue the access request for sync.',
    );
  }

  @override
  Future<AppResult<Unit>> queueRemoveAccess({
    required String userId,
    required Set<String> agentIds,
  }) {
    return _queueActions(
      userId: userId,
      agentIds: agentIds,
      type: PendingAgentActionType.removeAccess,
      operation: 'queueRemoveAccess',
      uiKey: ClientAgentsFailureUiKey.queueRemoveAccess,
      fallbackMessage: 'Unable to queue remove-access actions',
      fallbackUserMessage: 'Could not queue the removal for sync.',
    );
  }

  Future<AppResult<Unit>> _queueActions({
    required String userId,
    required Set<String> agentIds,
    required PendingAgentActionType type,
    required String operation,
    required String uiKey,
    required String fallbackMessage,
    required String fallbackUserMessage,
  }) {
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        final actions = await _localDataSource.readPendingActions(
          userId: userId,
        );
        final updated = _enqueueActions(
          currentActions: actions,
          agentIds: agentIds,
          type: type,
        );
        await _localDataSource.savePendingActions(
          userId: userId,
          actions: updated,
        );
        return unit;
      },
      fallbackMessage: fallbackMessage,
      fallbackUserMessage: fallbackUserMessage,
      context: <String, Object?>{
        'operation': operation,
        'userId': userId,
        ClientAgentsFailureUiKey.field: uiKey,
      },
    );
  }

  @override
  Future<AppResult<SyncPendingAgentActionsResult>> syncPendingActions({
    required String userId,
  }) {
    return withRepositoryErrorMappingNoCache<SyncPendingAgentActionsResult>(
      action: () async {
        final result = await _synchronizer.synchronize(userId: userId);
        await _refreshSnapshotsAfterSync(userId: userId);
        return result;
      },
      fallbackMessage: 'Unable to sync pending agent actions',
      fallbackUserMessage: 'Could not sync pending agent actions.',
      context: <String, Object?>{
        'operation': 'syncPendingActions',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.syncPendingActions,
      },
    );
  }

  @override
  Future<Set<String>?> loadOnlineAgentIds({required String userId}) {
    return _readOnlineAgentIds(
      userId: userId,
      maxAge: _onlineStatusMaxAge,
      fallbackToOfflineCache: true,
    );
  }

  /// Persists a synthetic `OnlineAgentsResponseDto` when [profiles] include
  /// `is_hub_connected`, so [loadOnlineAgentIds] and overview can resolve
  /// online ids without `GET /api/v1/agents` (user-only).
  Future<void> _persistHubPresenceCacheFromProfiles({
    required String userId,
    required Iterable<ClientAgentProfileDto> profiles,
  }) async {
    final synthetic = synthesizeOnlineAgentsDtoFromProfiles(
      profiles: profiles,
      stamp: DateTime.now(),
    );
    if (synthetic == null) {
      return;
    }
    await _localDataSource.saveOnlineAgents(
      userId: userId,
      payload: synthetic,
    );
  }

  Future<AppResult<Unit>> _performOwnerRequestMutation({
    required String userId,
    required String requestId,
    required String operation,
    required String uiKey,
    required String fallbackUserMessage,
    required Future<void> Function(String trimmedRequestId) action,
  }) {
    final validation = requireRequestId<Unit>(requestId);
    if (validation.failure != null) {
      return Future.value(validation.failure!);
    }
    final trimmed = validation.trimmed;
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        await action(trimmed);
        return unit;
      },
      fallbackMessage: 'Unable to mutate owner access request',
      fallbackUserMessage: fallbackUserMessage,
      context: <String, Object?>{
        'operation': operation,
        'userId': userId,
        'requestId': trimmed,
        ClientAgentsFailureUiKey.field: uiKey,
      },
    );
  }

  /// Cached hub presence only (no `GET /api/v1/agents` — client JWT is 403).
  /// When [fallbackToOfflineCache] is true, falls back to the wider
  /// `_onlineStatusOfflineFallbackMaxAge` window when the fresh window
  /// returns nothing.
  Future<Set<String>?> _readOnlineAgentIds({
    required String userId,
    required Duration maxAge,
    bool fallbackToOfflineCache = false,
  }) async {
    final primary = await _localDataSource.readOnlineAgents(
      userId: userId,
      maxAge: maxAge,
    );
    if (primary != null) {
      return primary.agents.map((item) => item.agentId).toSet();
    }
    if (!fallbackToOfflineCache) {
      return null;
    }
    final fallback = await _localDataSource.readOnlineAgents(
      userId: userId,
      maxAge: _onlineStatusOfflineFallbackMaxAge,
    );
    if (fallback == null) {
      return null;
    }
    return fallback.agents.map((item) => item.agentId).toSet();
  }

  Future<void> _applySnapshotToCachedAgentDetail({
    required String userId,
    required String agentId,
    required AgentProfileSnapshot snapshot,
  }) async {
    final cachedDetail = await _localDataSource.readApprovedAgentDetail(
      userId: userId,
      agentId: agentId,
    );
    if (cachedDetail == null) {
      return;
    }
    await _localDataSource.saveApprovedAgentDetail(
      userId: userId,
      agentId: agentId,
      payload: ClientApprovedAgentDetailResponseDto(
        agent: _applySnapshotToAccessibleAgent(cachedDetail.agent, snapshot),
      ),
    );
  }

  Future<void> _applySnapshotToCachedApprovedAgents({
    required String userId,
    required String agentId,
    required AgentProfileSnapshot snapshot,
  }) async {
    final approvedSnapshot = await _localDataSource.readApprovedAgents(
      userId: userId,
      query: _defaultRefreshQuery,
    );
    if (approvedSnapshot == null) {
      return;
    }
    var changed = false;
    final updatedAgents = approvedSnapshot.agents
        .map((agent) {
          if (agent.agentId != agentId) {
            return agent;
          }
          changed = true;
          return _applySnapshotToAccessibleAgent(agent, snapshot);
        })
        .toList(growable: false);
    if (!changed) {
      return;
    }
    await _localDataSource.saveApprovedAgents(
      userId: userId,
      query: _defaultRefreshQuery,
      payload: ClientApprovedAgentsResponseDto(
        agents: updatedAgents,
        agentIds: approvedSnapshot.agentIds,
        count: approvedSnapshot.count,
        total: approvedSnapshot.total,
        page: approvedSnapshot.page,
        pageSize: approvedSnapshot.pageSize,
      ),
    );
  }

  ClientAccessibleAgentDto _applySnapshotToAccessibleAgent(
    ClientAccessibleAgentDto base,
    AgentProfileSnapshot snapshot,
  ) {
    final normalizedDocument = snapshot.document?.trim();
    return base.copyWith(
      name: snapshot.name,
      tradeName: snapshot.tradeName,
      document: normalizedDocument,
      cnpjCpf: normalizedDocument,
      documentType: snapshot.documentType,
      phone: snapshot.phone,
      mobile: snapshot.mobile,
      email: snapshot.email,
      notes: snapshot.notes,
      observation: snapshot.observation,
      profileUpdatedAt: snapshot.profileUpdatedAt,
      profileVersion: snapshot.profileVersion,
    );
  }

  List<PendingAgentAction> _enqueueActions({
    required List<PendingAgentAction> currentActions,
    required Set<String> agentIds,
    required PendingAgentActionType type,
  }) {
    final updated = List<PendingAgentAction>.from(currentActions);
    for (final rawAgentId in agentIds) {
      final agentId = rawAgentId.trim();
      if (agentId.isEmpty) {
        continue;
      }
      final sameIndex = updated.indexWhere((action) {
        return action.agentId == agentId && action.type == type;
      });
      if (sameIndex != -1) {
        continue;
      }

      final oppositeType = type == PendingAgentActionType.requestAccess
          ? PendingAgentActionType.removeAccess
          : PendingAgentActionType.requestAccess;
      final oppositeIndex = updated.indexWhere((action) {
        return action.agentId == agentId && action.type == oppositeType;
      });
      if (oppositeIndex != -1) {
        updated.removeAt(oppositeIndex);
        if (type == PendingAgentActionType.removeAccess) {
          continue;
        }
      }

      updated.add(
        PendingAgentAction(
          id: '${type.name}_$agentId',
          agentId: agentId,
          type: type,
          state: PendingAgentActionState.queued,
          createdAt: DateTime.now(),
          attemptCount: 0,
        ),
      );
    }
    return updated;
  }

  Future<void> _refreshSnapshotsAfterSync({
    required String userId,
  }) async {
    await _runPostSyncStep(
      userId: userId,
      step: 'approvedAgents',
      run: () async {
        final approved = await _remoteDataSource.fetchApprovedAgents(
          query: _defaultRefreshQuery,
        );
        await _localDataSource.saveApprovedAgents(
          userId: userId,
          query: _defaultRefreshQuery,
          payload: approved,
        );
        await _persistHubPresenceCacheFromProfiles(
          userId: userId,
          profiles: approved.agents,
        );
      },
    );

    await _runPostSyncStep(
      userId: userId,
      step: 'accessRequests',
      run: () async {
        final requests = await _remoteDataSource.fetchAccessRequests(
          query: _defaultRefreshQuery,
        );
        await _localDataSource.saveAccessRequests(
          userId: userId,
          query: _defaultRefreshQuery,
          payload: requests,
        );
      },
    );

    await _readOnlineAgentIds(
      userId: userId,
      maxAge: _onlineStatusMaxAge,
      fallbackToOfflineCache: true,
    );
  }

  /// Best-effort runner for the post-sync refresh steps: swallows the
  /// error, logs a warning with the same shape as the legacy inline
  /// block, and lets the next step proceed.
  Future<void> _runPostSyncStep({
    required String userId,
    required String step,
    required Future<void> Function() run,
  }) async {
    try {
      await run();
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Post-sync refresh step failed',
        context: <String, Object?>{
          'operation': 'refreshSnapshotsAfterSync',
          'step': step,
          'userId': userId,
          'errorType': error.runtimeType.toString(),
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
