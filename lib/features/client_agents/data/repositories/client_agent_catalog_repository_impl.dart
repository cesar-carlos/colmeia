import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/repository_error_mapping.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_cache_support.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_response_mappers.dart';
import 'package:colmeia/features/client_agents/data/validation/client_agents_id_validators.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agent_catalog_repository.dart';

class ClientAgentCatalogRepositoryImpl implements ClientAgentCatalogRepository {
  ClientAgentCatalogRepositoryImpl({
    required this._remoteDataSource,
    required this._localDataSource,
    required this._cacheSupport,
  });

  final ClientAgentsRemoteDataSource _remoteDataSource;
  final ClientAgentsLocalDataSource _localDataSource;
  final ClientAgentsRepositoryCacheSupport _cacheSupport;

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
        await _cacheSupport.persistHubPresenceCacheFromProfiles(
          userId: userId,
          profiles: remote.agents,
        );
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
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
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport
              .onlineStatusOfflineFallbackMaxAge,
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
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
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
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport
              .onlineStatusOfflineFallbackMaxAge,
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
        final onlineIds = await _cacheSupport.readOnlineAgentIds(
          userId: userId,
          maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
        );
        return mapClientAgentProfile(remote, onlineIds: onlineIds);
      },
      fallbackMessage: 'Unable to update catalog agent profile',
      fallbackUserMessage: 'Could not update the agent profile on the server.',
      context: <String, Object?>{
        'operation': 'updateCatalogAgentProfile',
        'userId': userId,
        'agentId': trimmed,
      },
    );
  }
}
