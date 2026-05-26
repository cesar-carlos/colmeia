import 'dart:math' show min;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/repository_error_mapping.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_response_mappers.dart';
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
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:result_dart/result_dart.dart';

class ClientAgentsRepositoryImpl implements ClientAgentsRepository {
  ClientAgentsRepositoryImpl({
    required ClientAgentsRemoteDataSource remoteDataSource,
    required ClientAgentsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  static const Duration _onlineStatusMaxAge = Duration(minutes: 1);

  /// When the hub cannot be reached, use cached online presence only if it is
  /// newer than this limit; otherwise treat presence as unknown.
  static const Duration _onlineStatusOfflineFallbackMaxAge = Duration(days: 7);
  static const PaginatedQuery _defaultRefreshQuery = PaginatedQuery(
    pageSize: kClientAgentsListPageSize,
  );

  final ClientAgentsRemoteDataSource _remoteDataSource;
  final ClientAgentsLocalDataSource _localDataSource;

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
        final onlineIds = await _loadOnlineAgentIds(userId: userId);
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
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
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
    final trimmed = agentId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Failure<ClientAgentCatalogItem, AppFailure>(
          ValidationFailure(
            message: 'Agent id is empty',
            userMessage: 'Invalid agent identifier.',
          ),
        ),
      );
    }
    return withRepositoryErrorMapping<ClientAgentCatalogItem>(
      action: () async {
        final remote = await _remoteDataSource.fetchCatalogAgentById(trimmed);
        await _localDataSource.saveCatalogAgentById(
          userId: userId,
          agentId: trimmed,
          payload: remote,
        );
        final onlineIds = await _loadOnlineAgentIds(userId: userId);
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
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
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
    final trimmed = agentId.trim();
    if (trimmed.isEmpty) {
      return const Failure<ClientAgent, AppFailure>(
        ValidationFailure(
          message: 'Agent id is empty',
          userMessage: 'Invalid agent identifier.',
        ),
      );
    }
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
        final onlineIds = await _loadOnlineAgentIds(userId: userId);
        return mapClientAgentProfile(remote, onlineIds: onlineIds);
      },
      fallbackMessage: 'Unable to update catalog agent profile',
      fallbackUserMessage:
          'Nao foi possivel atualizar o perfil do agente no servidor.',
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
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return const Failure<Unit, AppFailure>(
        ValidationFailure(
          message: 'Agent id is empty',
          userMessage: 'Invalid agent identifier.',
        ),
      );
    }
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        final cachedDetail = await _localDataSource.readApprovedAgentDetail(
          userId: userId,
          agentId: trimmedAgentId,
        );
        if (cachedDetail != null) {
          await _localDataSource.saveApprovedAgentDetail(
            userId: userId,
            agentId: trimmedAgentId,
            payload: ClientApprovedAgentDetailResponseDto(
              agent: _applySnapshotToAccessibleAgent(
                cachedDetail.agent,
                snapshot,
              ),
            ),
          );
        }

        final approvedSnapshot = await _localDataSource.readApprovedAgents(
          userId: userId,
          query: _defaultRefreshQuery,
        );
        if (approvedSnapshot != null) {
          var changed = false;
          final updatedAgents = approvedSnapshot.agents
              .map((agent) {
                if (agent.agentId != trimmedAgentId) {
                  return agent;
                }
                changed = true;
                return _applySnapshotToAccessibleAgent(agent, snapshot);
              })
              .toList(growable: false);
          if (changed) {
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
        }

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
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return const Failure<ClientAccessStatusSnapshot, AppFailure>(
        ValidationFailure(
          message: 'Client access token is empty',
          userMessage: 'Invalid access link.',
        ),
      );
    }
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
            ? await _loadOnlineAgentIds(userId: userId)
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
            ? await _readCachedOnlineAgentIds(userId: userId)
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
        final onlineIds = await _loadOnlineAgentIds(userId: userId);
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
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
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
        final onlineIds = await _loadOnlineAgentIds(userId: userId);
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
      PaginatedResult<ClientAgentAccessRequest>
    >(
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
    final trimmed = requestId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Failure<Unit, AppFailure>(
          ValidationFailure(
            message: 'Request id is empty',
            userMessage: 'Identificador de solicitacao invalido.',
          ),
        ),
      );
    }
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
        final onlineIds = await _loadOnlineAgentIds(userId: userId);
        return remote.agents
            .map((agent) => mapClientAgentProfile(agent, onlineIds: onlineIds))
            .toList(growable: false);
      },
      cacheFallback: (_) async {
        final cached = await _localDataSource.readManagedAgents(userId: userId);
        if (cached == null) {
          return null;
        }
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
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
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return Future.value(
        const Failure<List<OwnerApprovedClient>, AppFailure>(
          ValidationFailure(
            message: 'Agent id is empty',
            userMessage: 'Identificador de agente invalido.',
          ),
        ),
      );
    }
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
    final trimmedAgentId = agentId.trim();
    final trimmedClientId = clientId.trim();
    if (trimmedAgentId.isEmpty || trimmedClientId.isEmpty) {
      return Future.value(
        const Failure<Unit, AppFailure>(
          ValidationFailure(
            message: 'Agent or client id is empty',
            userMessage: 'Identificador invalido para revogar o acesso.',
          ),
        ),
      );
    }
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
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        final actions = await _localDataSource.readPendingActions(
          userId: userId,
        );
        final updated = _enqueueActions(
          currentActions: actions,
          agentIds: agentIds,
          type: PendingAgentActionType.requestAccess,
        );
        await _localDataSource.savePendingActions(
          userId: userId,
          actions: updated,
        );
        return unit;
      },
      fallbackMessage: 'Unable to queue request-access actions',
      fallbackUserMessage: 'Could not queue the access request for sync.',
      context: <String, Object?>{
        'operation': 'queueRequestAccess',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.queueRequestAccess,
      },
    );
  }

  @override
  Future<AppResult<Unit>> queueRemoveAccess({
    required String userId,
    required Set<String> agentIds,
  }) {
    return withRepositoryErrorMappingNoCache<Unit>(
      action: () async {
        final actions = await _localDataSource.readPendingActions(
          userId: userId,
        );
        final updated = _enqueueActions(
          currentActions: actions,
          agentIds: agentIds,
          type: PendingAgentActionType.removeAccess,
        );
        await _localDataSource.savePendingActions(
          userId: userId,
          actions: updated,
        );
        return unit;
      },
      fallbackMessage: 'Unable to queue remove-access actions',
      fallbackUserMessage: 'Could not queue the removal for sync.',
      context: <String, Object?>{
        'operation': 'queueRemoveAccess',
        'userId': userId,
        ClientAgentsFailureUiKey.field:
            ClientAgentsFailureUiKey.queueRemoveAccess,
      },
    );
  }

  Future<List<PendingAgentAction>> _recoverStaleSyncingPendingActions({
    required String userId,
    required List<PendingAgentAction> actions,
  }) async {
    final staleCount = actions
        .where((a) => a.state == PendingAgentActionState.syncing)
        .length;
    if (staleCount == 0) {
      return actions;
    }
    final recovered = actions
        .map(
          (a) => a.state == PendingAgentActionState.syncing
              ? a.copyWith(
                  state: PendingAgentActionState.queued,
                  clearErrorMessage: true,
                )
              : a,
        )
        .toList(growable: false);
    await _localDataSource.savePendingActions(
      userId: userId,
      actions: recovered,
    );
    AppLogger.info(
      'Recovered orphaned syncing client-agent pending actions',
      context: <String, Object?>{
        'operation': 'recoverStaleSyncingPendingActions',
        'userId': userId,
        'recoveredCount': staleCount,
      },
    );
    return recovered;
  }

  @override
  Future<AppResult<SyncPendingAgentActionsResult>> syncPendingActions({
    required String userId,
  }) async {
    try {
      var current = await _localDataSource.readPendingActions(userId: userId);
      current = await _recoverStaleSyncingPendingActions(
        userId: userId,
        actions: current,
      );
      final syncCandidates = current
          .where(
            (action) =>
                action.state == PendingAgentActionState.queued ||
                action.state == PendingAgentActionState.failed,
          )
          .toList(growable: false);

      if (syncCandidates.isEmpty) {
        return const Success<SyncPendingAgentActionsResult, AppFailure>(
          SyncPendingAgentActionsResult(),
        );
      }

      final syncingIds = syncCandidates.map((item) => item.id).toSet();
      var working = current
          .map(
            (action) => syncingIds.contains(action.id)
                ? action.copyWith(
                    state: PendingAgentActionState.syncing,
                    lastAttemptAt: DateTime.now(),
                    attemptCount: action.attemptCount + 1,
                  )
                : action,
          )
          .toList(growable: true);
      await _localDataSource.savePendingActions(
        userId: userId,
        actions: working,
      );

      final successfulIds = <String>{};
      final successfulRequestAccessAgentIds = <String>{};
      final successfulRemoveAccessAgentIds = <String>{};
      final failedRequestAccessAgentIds = <String>{};
      final failedRemoveAccessAgentIds = <String>{};
      final requestAccessPollAgentIds = <String>{};
      final requestAccessAlreadyApprovedAgentIds = <String>{};
      final requestAccessDebouncedAgentIds = <String>{};
      final requestAccessNewRequestsAgentIds = <String>{};

      final requestActions = syncCandidates
          .where((a) => a.type == PendingAgentActionType.requestAccess)
          .toList(growable: false);
      final removeActions = syncCandidates
          .where((a) => a.type == PendingAgentActionType.removeAccess)
          .toList(growable: false);

      final chunkIds = <String>{};
      for (var start = 0; start < requestActions.length;) {
        final end =
            (start + kClientAgentsRequestAccessSyncBatchSize) >
                requestActions.length
            ? requestActions.length
            : start + kClientAgentsRequestAccessSyncBatchSize;
        final chunk = requestActions.sublist(start, end);
        start = end;
        chunkIds
          ..clear()
          ..addAll(chunk.map((a) => a.agentId));
        try {
          final accessResponse = await _remoteDataSource.requestAccess(
            agentIds: Set<String>.from(chunkIds),
          );
          final unacknowledged = <PendingAgentAction>[];
          for (final action in chunk) {
            final agentId = action.agentId;
            if (!accessResponse.acknowledgesAgent(agentId)) {
              unacknowledged.add(action);
            }
          }
          if (unacknowledged.isNotEmpty) {
            const notAcknowledged = ValidationFailure(
              message: 'POST /client/me/agents omitted an agent id in the body',
              userMessage:
                  'The server did not confirm one or more access requests.',
            );
            for (final action in unacknowledged) {
              failedRequestAccessAgentIds.add(action.agentId);
            }
            final failedIds = unacknowledged.map((a) => a.id).toSet();
            working = working
                .map((currentAction) {
                  if (!failedIds.contains(currentAction.id)) {
                    return currentAction;
                  }
                  return currentAction.copyWith(
                    state: PendingAgentActionState.failed,
                    errorMessage: notAcknowledged.displayMessage,
                  );
                })
                .toList(growable: false);
            await _localDataSource.savePendingActions(
              userId: userId,
              actions: working,
            );
          }
          for (final action in chunk) {
            if (unacknowledged.any((a) => a.id == action.id)) {
              continue;
            }
            final agentId = action.agentId;
            successfulIds.add(action.id);
            successfulRequestAccessAgentIds.add(agentId);
            if (accessResponse.shouldPollApprovalFor(agentId)) {
              requestAccessPollAgentIds.add(agentId);
            }
            if (accessResponse.alreadyApproved.contains(agentId)) {
              requestAccessAlreadyApprovedAgentIds.add(agentId);
            }
            if (accessResponse.debounced.contains(agentId)) {
              requestAccessDebouncedAgentIds.add(agentId);
            }
            if (accessResponse.newRequests.contains(agentId)) {
              requestAccessNewRequestsAgentIds.add(agentId);
            }
          }
          AppLogger.info(
            'Synced client agent request-access batch',
            context: <String, Object?>{
              'operation': 'syncPendingActions',
              'userId': userId,
              'batchSize': chunk.length,
            },
          );
        } on Object catch (error, stackTrace) {
          final failure = mapToAppFailure(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Unable to sync agent action',
            fallbackUserMessage: 'Could not sync the change for this agent.',
            context: <String, Object?>{
              'operation': 'syncPendingAction',
              'userId': userId,
              'agentIds': kDebugMode
                  ? chunkIds.join(',')
                  : '${chunkIds.length} ids',
              'actionType': PendingAgentActionType.requestAccess.name,
              ClientAgentsFailureUiKey.field:
                  ClientAgentsFailureUiKey.syncPendingAction,
            },
          );
          for (final action in chunk) {
            failedRequestAccessAgentIds.add(action.agentId);
          }
          final failedChunkIds = chunk.map((a) => a.id).toSet();
          working = working
              .map((currentAction) {
                if (!failedChunkIds.contains(currentAction.id)) {
                  return currentAction;
                }
                return currentAction.copyWith(
                  state: PendingAgentActionState.failed,
                  errorMessage: failure.displayMessage,
                );
              })
              .toList(growable: false);
          await _localDataSource.savePendingActions(
            userId: userId,
            actions: working,
          );
        }
      }

      if (removeActions.isNotEmpty) {
        final removeOutcomes = <(PendingAgentAction, AppFailure?)>[];
        for (var i = 0; i < removeActions.length;) {
          final end = min(
            i + kClientAgentsRemoveAccessSyncConcurrency,
            removeActions.length,
          );
          final chunk = removeActions.sublist(i, end);
          i = end;
          final batch = await Future.wait(
            chunk.map((action) async {
              try {
                await _remoteDataSource.removeApprovedAgentById(action.agentId);
                return (action, null as AppFailure?);
              } on Object catch (error, stackTrace) {
                final failure = mapToAppFailure(
                  error,
                  stackTrace: stackTrace,
                  fallbackMessage: 'Unable to sync agent action',
                  fallbackUserMessage:
                      'Could not sync the change for this agent.',
                  context: <String, Object?>{
                    'operation': 'syncPendingAction',
                    'userId': userId,
                    'agentId': action.agentId,
                    'actionType': action.type.name,
                    ClientAgentsFailureUiKey.field:
                        ClientAgentsFailureUiKey.syncPendingAction,
                  },
                );
                return (action, failure);
              }
            }),
          );
          removeOutcomes.addAll(batch);
        }
        for (final record in removeOutcomes) {
          final action = record.$1;
          final failure = record.$2;
          if (failure == null) {
            successfulIds.add(action.id);
            successfulRemoveAccessAgentIds.add(action.agentId);
          } else {
            failedRemoveAccessAgentIds.add(action.agentId);
            working = working
                .map((currentAction) {
                  if (currentAction.id != action.id) {
                    return currentAction;
                  }
                  return currentAction.copyWith(
                    state: PendingAgentActionState.failed,
                    errorMessage: failure.displayMessage,
                  );
                })
                .toList(growable: false);
          }
        }
        await _localDataSource.savePendingActions(
          userId: userId,
          actions: working,
        );
        AppLogger.info(
          'Synced client agent remove-access operations',
          context: <String, Object?>{
            'operation': 'syncPendingActions',
            'userId': userId,
            'count': removeActions.length,
            'ok': successfulRemoveAccessAgentIds.length,
            'failed': failedRemoveAccessAgentIds.length,
          },
        );
      }

      AppLogger.info(
        'Client agents pending sync summary',
        context: <String, Object?>{
          'operation': 'syncPendingActions',
          'userId': userId,
          'requestAccessOk': successfulRequestAccessAgentIds.length,
          'requestAccessFailed': failedRequestAccessAgentIds.length,
          'removeAccessOk': successfulRemoveAccessAgentIds.length,
          'removeAccessFailed': failedRemoveAccessAgentIds.length,
          'approvalPollIds': requestAccessPollAgentIds.length,
          'newRequestsIds': requestAccessNewRequestsAgentIds.length,
        },
      );

      working = working
          .where(
            (action) =>
                !syncingIds.contains(action.id) ||
                !successfulIds.contains(action.id),
          )
          .toList(growable: false);
      await _localDataSource.savePendingActions(
        userId: userId,
        actions: working,
      );
      if (successfulRemoveAccessAgentIds.isNotEmpty) {
        await Future.wait(
          successfulRemoveAccessAgentIds.map(
            (agentId) => _localDataSource.clearApprovedAgentDetail(
              userId: userId,
              agentId: agentId,
            ),
          ),
        );
      }

      await _refreshSnapshotsAfterSync(userId: userId);
      return Success<SyncPendingAgentActionsResult, AppFailure>(
        SyncPendingAgentActionsResult(
          successfulRequestAccessAgentIds: successfulRequestAccessAgentIds,
          successfulRemoveAccessAgentIds: successfulRemoveAccessAgentIds,
          failedRequestAccessAgentIds: failedRequestAccessAgentIds,
          failedRemoveAccessAgentIds: failedRemoveAccessAgentIds,
          requestAccessPollAgentIds: requestAccessPollAgentIds,
          requestAccessAlreadyApprovedAgentIds:
              requestAccessAlreadyApprovedAgentIds,
          requestAccessDebouncedAgentIds: requestAccessDebouncedAgentIds,
          requestAccessNewRequestsAgentIds: requestAccessNewRequestsAgentIds,
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failure<SyncPendingAgentActionsResult, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to sync pending agent actions',
          fallbackUserMessage: 'Could not sync pending agent actions.',
          context: <String, Object?>{
            'operation': 'syncPendingActions',
            'userId': userId,
            ClientAgentsFailureUiKey.field:
                ClientAgentsFailureUiKey.syncPendingActions,
          },
        ),
      );
    }
  }

  @override
  Future<Set<String>?> loadOnlineAgentIds({required String userId}) {
    return _loadOnlineAgentIds(userId: userId);
  }

  /// Writes a synthetic [OnlineAgentsResponseDto] when profile rows include
  /// [ClientAgentProfileDto.isHubConnected], so [loadOnlineAgentIds] and
  /// overview can resolve online ids without `GET /api/v1/agents` (user-only).
  Future<void> _persistHubPresenceCacheFromProfiles({
    required String userId,
    required Iterable<ClientAgentProfileDto> profiles,
  }) async {
    if (!profiles.any((a) => a.isHubConnected != null)) {
      return;
    }
    final stamp = DateTime.now();
    final online = <OnlineAgentDto>[
      for (final a in profiles)
        if (a.isHubConnected == true)
          OnlineAgentDto(
            agentId: a.agentId,
            connectedAt: stamp,
            lastSeenAt: stamp,
          ),
    ];
    await _localDataSource.saveOnlineAgents(
      userId: userId,
      payload: OnlineAgentsResponseDto(agents: online, count: online.length),
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
    final trimmed = requestId.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Failure<Unit, AppFailure>(
          ValidationFailure(
            message: 'Request id is empty',
            userMessage: 'Identificador de solicitacao invalido.',
          ),
        ),
      );
    }
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
  Future<Set<String>?> _loadOnlineAgentIds({
    required String userId,
  }) async {
    final freshCached = await _localDataSource.readOnlineAgents(
      userId: userId,
      maxAge: _onlineStatusMaxAge,
    );
    if (freshCached != null) {
      return freshCached.agents.map((item) => item.agentId).toSet();
    }
    return _readCachedOnlineAgentIds(userId: userId);
  }

  Future<Set<String>?> _readCachedOnlineAgentIds({
    required String userId,
  }) async {
    final cached = await _localDataSource.readOnlineAgents(
      userId: userId,
      maxAge: _onlineStatusOfflineFallbackMaxAge,
    );
    if (cached == null) {
      return null;
    }
    return cached.agents.map((item) => item.agentId).toSet();
  }

  ClientAccessibleAgentDto _applySnapshotToAccessibleAgent(
    ClientAccessibleAgentDto base,
    AgentProfileSnapshot snapshot,
  ) {
    final normalizedDocument = snapshot.document?.trim();
    return ClientAccessibleAgentDto(
      agentId: base.agentId,
      name: snapshot.name,
      status: base.status,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      tradeName: snapshot.tradeName ?? base.tradeName,
      document: normalizedDocument ?? base.document,
      cnpjCpf: normalizedDocument ?? base.cnpjCpf,
      documentType: snapshot.documentType ?? base.documentType,
      phone: snapshot.phone ?? base.phone,
      mobile: snapshot.mobile ?? base.mobile,
      email: snapshot.email ?? base.email,
      address: base.address,
      notes: snapshot.notes ?? base.notes,
      observation: snapshot.observation ?? base.observation,
      profileUpdatedAt: snapshot.profileUpdatedAt ?? base.profileUpdatedAt,
      profileVersion: snapshot.profileVersion ?? base.profileVersion,
      isHubConnected: base.isHubConnected,
      hasClientToken: base.hasClientToken,
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
    try {
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
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Post-sync refresh of approved agents snapshot failed',
        context: <String, Object?>{
          'operation': 'refreshSnapshotsAfterSync',
          'step': 'approvedAgents',
          'userId': userId,
          'errorType': error.runtimeType.toString(),
        },
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      final requests = await _remoteDataSource.fetchAccessRequests(
        query: _defaultRefreshQuery,
      );
      await _localDataSource.saveAccessRequests(
        userId: userId,
        query: _defaultRefreshQuery,
        payload: requests,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Post-sync refresh of access requests snapshot failed',
        context: <String, Object?>{
          'operation': 'refreshSnapshotsAfterSync',
          'step': 'accessRequests',
          'userId': userId,
          'errorType': error.runtimeType.toString(),
        },
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _loadOnlineAgentIds(userId: userId);
  }
}
