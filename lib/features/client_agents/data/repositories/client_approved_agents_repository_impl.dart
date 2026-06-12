import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/repository_error_mapping.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_cache_support.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_response_mappers.dart';
import 'package:colmeia/features/client_agents/data/validation/client_agents_id_validators.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_approved_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class ClientApprovedAgentsRepositoryImpl
    implements ClientApprovedAgentsRepository {
  ClientApprovedAgentsRepositoryImpl({
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
          await _cacheSupport.persistHubPresenceCacheFromProfiles(
            userId: userId,
            profiles: remote.agents,
          );
        }
        final onlineIds = includeOnlineStatus
            ? await _cacheSupport.readOnlineAgentIds(
                userId: userId,
                maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
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
            ? await _cacheSupport.readOnlineAgentIds(
                userId: userId,
                maxAge: ClientAgentsRepositoryCacheSupport
                    .onlineStatusOfflineFallbackMaxAge,
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
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
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
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge:
              ClientAgentsRepositoryCacheSupport.onlineStatusOfflineFallbackMaxAge,
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
        await _cacheSupport.persistHubPresenceCacheFromProfiles(
          userId: userId,
          profiles: <ClientAgentProfileDto>[remote.agent],
        );
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
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
        await _cacheSupport.applySnapshotToCachedAgentDetail(
          userId: userId,
          agentId: trimmedAgentId,
          snapshot: snapshot,
        );
        await _cacheSupport.applySnapshotToCachedApprovedAgents(
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
  Future<Set<String>?> loadOnlineAgentIds({required String userId}) {
    return _cacheSupport.readOnlineAgentIds(
      userId: userId,
      maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
      fallbackToOfflineCache: true,
    );
  }
}
