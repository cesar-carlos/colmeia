import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/repository_error_mapping.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_cache_support.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_response_mappers.dart';
import 'package:colmeia/features/client_agents/data/validation/client_agents_id_validators.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:colmeia/features/client_agents/domain/repositories/owner_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class OwnerAgentsRepositoryImpl implements OwnerAgentsRepository {
  OwnerAgentsRepositoryImpl({
    required ClientAgentsRemoteDataSource remoteDataSource,
    required ClientAgentsLocalDataSource localDataSource,
    required ClientAgentsRepositoryCacheSupport cacheSupport,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _cacheSupport = cacheSupport;

  final ClientAgentsRemoteDataSource _remoteDataSource;
  final ClientAgentsLocalDataSource _localDataSource;
  final ClientAgentsRepositoryCacheSupport _cacheSupport;

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
        await _cacheSupport.persistHubPresenceCacheFromProfiles(
          userId: userId,
          profiles: remote.agents,
        );
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
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
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport
              .onlineStatusOfflineFallbackMaxAge,
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
}
