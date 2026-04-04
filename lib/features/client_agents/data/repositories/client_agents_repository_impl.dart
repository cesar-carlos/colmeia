import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class ClientAgentsRepositoryImpl implements ClientAgentsRepository {
  ClientAgentsRepositoryImpl({
    required ClientAgentsRemoteDataSource remoteDataSource,
    required ClientAgentsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  static const Duration _onlineStatusMaxAge = Duration(minutes: 1);
  static const PaginatedQuery _defaultRefreshQuery = PaginatedQuery(
    pageSize: 100,
  );

  final ClientAgentsRemoteDataSource _remoteDataSource;
  final ClientAgentsLocalDataSource _localDataSource;

  @override
  Future<AppResult<PaginatedResult<ClientAgentCatalogItem>>> loadCatalog({
    required String userId,
    required PaginatedQuery query,
    String? search,
  }) async {
    try {
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
      final onlineIds = await _loadOnlineAgentIds(userId: userId);
      return Success<PaginatedResult<ClientAgentCatalogItem>, AppFailure>(
        _mapCatalog(remote, onlineIds: onlineIds),
      );
    } on DioException catch (error, stackTrace) {
      final cached = await _localDataSource.readCatalog(
        userId: userId,
        query: query,
        search: search,
      );
      if (cached != null) {
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
        return Success<PaginatedResult<ClientAgentCatalogItem>, AppFailure>(
          _mapCatalog(cached, onlineIds: onlineIds),
        );
      }
      return Failure<PaginatedResult<ClientAgentCatalogItem>, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load agent catalog',
          fallbackUserMessage:
              'Nao foi possivel carregar o catalogo de agentes.',
          context: <String, Object?>{
            'operation': 'loadClientAgentCatalog',
            'userId': userId,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      final cached = await _localDataSource.readCatalog(
        userId: userId,
        query: query,
        search: search,
      );
      if (cached != null) {
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
        return Success<PaginatedResult<ClientAgentCatalogItem>, AppFailure>(
          _mapCatalog(cached, onlineIds: onlineIds),
        );
      }
      return Failure<PaginatedResult<ClientAgentCatalogItem>, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load agent catalog',
          fallbackUserMessage:
              'Nao foi possivel carregar o catalogo de agentes.',
          context: <String, Object?>{
            'operation': 'loadClientAgentCatalog',
            'userId': userId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<PaginatedResult<ClientAgent>>> loadApprovedAgents({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) async {
    try {
      final remote = await _remoteDataSource.fetchApprovedAgents(
        query: query,
        search: search,
        status: status,
      );
      await _localDataSource.saveApprovedAgents(
        userId: userId,
        query: query,
        search: search,
        status: status,
        payload: remote,
      );
      final onlineIds = await _loadOnlineAgentIds(userId: userId);
      return Success<PaginatedResult<ClientAgent>, AppFailure>(
        _mapApproved(remote, onlineIds: onlineIds),
      );
    } on DioException catch (error, stackTrace) {
      final cached = await _localDataSource.readApprovedAgents(
        userId: userId,
        query: query,
        search: search,
        status: status,
      );
      if (cached != null) {
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
        return Success<PaginatedResult<ClientAgent>, AppFailure>(
          _mapApproved(cached, onlineIds: onlineIds),
        );
      }
      return Failure<PaginatedResult<ClientAgent>, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load approved client agents',
          fallbackUserMessage:
              'Nao foi possivel carregar os agentes aprovados para esta conta.',
          context: <String, Object?>{
            'operation': 'loadApprovedClientAgents',
            'userId': userId,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      final cached = await _localDataSource.readApprovedAgents(
        userId: userId,
        query: query,
        search: search,
        status: status,
      );
      if (cached != null) {
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
        return Success<PaginatedResult<ClientAgent>, AppFailure>(
          _mapApproved(cached, onlineIds: onlineIds),
        );
      }
      return Failure<PaginatedResult<ClientAgent>, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load approved client agents',
          fallbackUserMessage:
              'Nao foi possivel carregar os agentes aprovados para esta conta.',
          context: <String, Object?>{
            'operation': 'loadApprovedClientAgents',
            'userId': userId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<ClientAgent>> loadApprovedAgentById({
    required String userId,
    required String agentId,
  }) async {
    try {
      final remote = await _remoteDataSource.fetchApprovedAgentById(agentId);
      await _localDataSource.saveApprovedAgentDetail(
        userId: userId,
        agentId: agentId,
        payload: remote,
      );
      final onlineIds = await _loadOnlineAgentIds(userId: userId);
      return Success<ClientAgent, AppFailure>(
        _mapProfile(remote.agent, onlineIds: onlineIds),
      );
    } on DioException catch (error, stackTrace) {
      final cached = await _localDataSource.readApprovedAgentDetail(
        userId: userId,
        agentId: agentId,
      );
      if (cached != null) {
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
        return Success<ClientAgent, AppFailure>(
          _mapProfile(cached.agent, onlineIds: onlineIds),
        );
      }
      return Failure<ClientAgent, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load approved agent detail',
          fallbackUserMessage: 'Nao foi possivel carregar os dados do agente.',
          context: <String, Object?>{
            'operation': 'loadApprovedAgentById',
            'userId': userId,
            'agentId': agentId,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      final cached = await _localDataSource.readApprovedAgentDetail(
        userId: userId,
        agentId: agentId,
      );
      if (cached != null) {
        final onlineIds = await _readCachedOnlineAgentIds(userId: userId);
        return Success<ClientAgent, AppFailure>(
          _mapProfile(cached.agent, onlineIds: onlineIds),
        );
      }
      return Failure<ClientAgent, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load approved agent detail',
          fallbackUserMessage: 'Nao foi possivel carregar os dados do agente.',
          context: <String, Object?>{
            'operation': 'loadApprovedAgentById',
            'userId': userId,
            'agentId': agentId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<PaginatedResult<ClientAgentAccessRequest>>>
  loadAccessRequests({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) async {
    try {
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
      return Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
        _mapAccessRequests(remote),
      );
    } on DioException catch (error, stackTrace) {
      final cached = await _localDataSource.readAccessRequests(
        userId: userId,
        query: query,
        search: search,
        status: status,
      );
      if (cached != null) {
        return Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
          _mapAccessRequests(cached),
        );
      }
      return Failure<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load access requests',
          fallbackUserMessage:
              'Nao foi possivel carregar o historico de solicitacoes.',
          context: <String, Object?>{
            'operation': 'loadAccessRequests',
            'userId': userId,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      final cached = await _localDataSource.readAccessRequests(
        userId: userId,
        query: query,
        search: search,
        status: status,
      );
      if (cached != null) {
        return Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
          _mapAccessRequests(cached),
        );
      }
      return Failure<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load access requests',
          fallbackUserMessage:
              'Nao foi possivel carregar o historico de solicitacoes.',
          context: <String, Object?>{
            'operation': 'loadAccessRequests',
            'userId': userId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PendingAgentAction>>> readPendingActions({
    required String userId,
  }) async {
    try {
      final actions = await _localDataSource.readPendingActions(userId: userId);
      return Success<List<PendingAgentAction>, AppFailure>(actions);
    } on Object catch (error, stackTrace) {
      return Failure<List<PendingAgentAction>, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read pending actions',
          fallbackUserMessage:
              'Nao foi possivel carregar as acoes pendentes de sincronizacao.',
          context: <String, Object?>{
            'operation': 'readPendingClientAgentActions',
            'userId': userId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<Unit>> queueRequestAccess({
    required String userId,
    required Set<String> agentIds,
  }) async {
    try {
      final actions = await _localDataSource.readPendingActions(userId: userId);
      final approvedIds = await _readApprovedIds(userId: userId);
      final updated = _enqueueActions(
        currentActions: actions,
        agentIds: agentIds,
        type: PendingAgentActionType.requestAccess,
        approvedAgentIds: approvedIds,
      );
      await _localDataSource.savePendingActions(
        userId: userId,
        actions: updated,
      );
      return const Success<Unit, AppFailure>(unit);
    } on Object catch (error, stackTrace) {
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to queue request-access actions',
          fallbackUserMessage:
              'Nao foi possivel registrar a solicitacao para sincronizacao.',
          context: <String, Object?>{
            'operation': 'queueRequestAccess',
            'userId': userId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<Unit>> queueRemoveAccess({
    required String userId,
    required Set<String> agentIds,
  }) async {
    try {
      final actions = await _localDataSource.readPendingActions(userId: userId);
      final approvedIds = await _readApprovedIds(userId: userId);
      final updated = _enqueueActions(
        currentActions: actions,
        agentIds: agentIds,
        type: PendingAgentActionType.removeAccess,
        approvedAgentIds: approvedIds,
      );
      await _localDataSource.savePendingActions(
        userId: userId,
        actions: updated,
      );
      return const Success<Unit, AppFailure>(unit);
    } on Object catch (error, stackTrace) {
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to queue remove-access actions',
          fallbackUserMessage:
              'Nao foi possivel registrar a remocao para sincronizacao.',
          context: <String, Object?>{
            'operation': 'queueRemoveAccess',
            'userId': userId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<Unit>> syncPendingActions({
    required String userId,
  }) async {
    try {
      final current = await _localDataSource.readPendingActions(userId: userId);
      final syncCandidates = current
          .where(
            (action) =>
                action.state == PendingAgentActionState.queued ||
                action.state == PendingAgentActionState.failed,
          )
          .toList(growable: false);

      if (syncCandidates.isEmpty) {
        return const Success<Unit, AppFailure>(unit);
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
      for (final action in syncCandidates) {
        try {
          switch (action.type) {
            case PendingAgentActionType.requestAccess:
              await _remoteDataSource.requestAccess(
                agentIds: <String>{action.agentId},
              );
            case PendingAgentActionType.removeAccess:
              await _remoteDataSource.removeAccess(
                agentIds: <String>{action.agentId},
              );
          }
          successfulIds.add(action.id);
        } on Object catch (error, stackTrace) {
          final failure = mapToAppFailure(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Unable to sync agent action',
            fallbackUserMessage:
                'Nao foi possivel sincronizar a alteracao do agente.',
            context: <String, Object?>{
              'operation': 'syncPendingAction',
              'userId': userId,
              'agentId': action.agentId,
              'actionType': action.type.name,
            },
          );
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
          await _localDataSource.savePendingActions(
            userId: userId,
            actions: working,
          );
        }
      }

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

      await _refreshSnapshotsAfterSync(userId: userId);
      return const Success<Unit, AppFailure>(unit);
    } on Object catch (error, stackTrace) {
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to sync pending agent actions',
          fallbackUserMessage:
              'Nao foi possivel sincronizar as acoes pendentes de agentes.',
          context: <String, Object?>{
            'operation': 'syncPendingActions',
            'userId': userId,
          },
        ),
      );
    }
  }

  PaginatedResult<ClientAgentCatalogItem> _mapCatalog(
    PaginatedAgentCatalogResponseDto response, {
    required Set<String>? onlineIds,
  }) {
    final items = response.agents
        .map((agent) {
          return ClientAgentCatalogItem(
            agent: _mapProfile(agent, onlineIds: onlineIds),
          );
        })
        .toList(growable: false);
    return PaginatedResult<ClientAgentCatalogItem>(
      items: items,
      count: response.count,
      total: response.total,
      page: response.page,
      pageSize: response.pageSize,
    );
  }

  PaginatedResult<ClientAgent> _mapApproved(
    ClientApprovedAgentsResponseDto response, {
    required Set<String>? onlineIds,
  }) {
    final items = response.agents
        .map((agent) => _mapProfile(agent, onlineIds: onlineIds))
        .toList(growable: false);
    return PaginatedResult<ClientAgent>(
      items: items,
      count: response.count,
      total: response.total,
      page: response.page,
      pageSize: response.pageSize,
    );
  }

  PaginatedResult<ClientAgentAccessRequest> _mapAccessRequests(
    ClientAccessRequestsResponseDto response,
  ) {
    return PaginatedResult<ClientAgentAccessRequest>(
      items: response.requests
          .map((request) => request.toEntity())
          .toList(growable: false),
      count: response.count,
      total: response.total,
      page: response.page,
      pageSize: response.pageSize,
    );
  }

  ClientAgent _mapProfile(
    ClientAgentProfileDto profile, {
    required Set<String>? onlineIds,
  }) {
    final connectionStatus = switch (onlineIds) {
      null => AgentConnectionStatus.unknown,
      final ids when ids.contains(profile.agentId) =>
        AgentConnectionStatus.online,
      _ => AgentConnectionStatus.offline,
    };
    return profile.toEntity(connectionStatus: connectionStatus);
  }

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

    try {
      final online = await _remoteDataSource.fetchOnlineAgents();
      await _localDataSource.saveOnlineAgents(userId: userId, payload: online);
      return online.agents.map((item) => item.agentId).toSet();
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Unable to refresh online agent status',
        context: <String, Object?>{
          'operation': 'refreshOnlineAgentStatus',
          'userId': userId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return _readCachedOnlineAgentIds(userId: userId);
    }
  }

  Future<Set<String>?> _readCachedOnlineAgentIds({
    required String userId,
  }) async {
    final cached = await _localDataSource.readOnlineAgents(userId: userId);
    if (cached == null) {
      return null;
    }
    return cached.agents.map((item) => item.agentId).toSet();
  }

  Future<Set<String>> _readApprovedIds({
    required String userId,
  }) async {
    final approved = await _localDataSource.readApprovedAgents(
      userId: userId,
      query: _defaultRefreshQuery,
    );
    if (approved != null) {
      return approved.agentIds;
    }

    final fallbackApproved = await _localDataSource.readApprovedAgents(
      userId: userId,
      query: const PaginatedQuery(pageSize: 50),
    );
    return fallbackApproved?.agentIds ?? const <String>{};
  }

  List<PendingAgentAction> _enqueueActions({
    required List<PendingAgentAction> currentActions,
    required Set<String> agentIds,
    required PendingAgentActionType type,
    required Set<String> approvedAgentIds,
  }) {
    final updated = List<PendingAgentAction>.from(currentActions);
    for (final agentId in agentIds) {
      if (type == PendingAgentActionType.requestAccess &&
          approvedAgentIds.contains(agentId)) {
        continue;
      }
      if (type == PendingAgentActionType.removeAccess &&
          !approvedAgentIds.contains(agentId)) {
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
    } on Object catch (_) {}

    try {
      final requests = await _remoteDataSource.fetchAccessRequests(
        query: _defaultRefreshQuery,
      );
      await _localDataSource.saveAccessRequests(
        userId: userId,
        query: _defaultRefreshQuery,
        payload: requests,
      );
    } on Object catch (_) {}

    await _loadOnlineAgentIds(userId: userId);
  }
}
