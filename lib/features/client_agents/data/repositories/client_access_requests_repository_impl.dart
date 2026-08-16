import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/repository_error_mapping.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_cache_support.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_response_mappers.dart';
import 'package:colmeia/features/client_agents/data/sync/pending_client_agent_actions_synchronizer.dart';
import 'package:colmeia/features/client_agents/data/validation/client_agents_id_validators.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_access_requests_repository.dart';
import 'package:result_dart/result_dart.dart';

class ClientAccessRequestsRepositoryImpl
    implements ClientAccessRequestsRepository {
  ClientAccessRequestsRepositoryImpl({
    required this._remoteDataSource,
    required this._localDataSource,
    required this._cacheSupport,
    required this._synchronizer,
  });

  final ClientAgentsRemoteDataSource _remoteDataSource;
  final ClientAgentsLocalDataSource _localDataSource;
  final ClientAgentsRepositoryCacheSupport _cacheSupport;
  final PendingClientAgentActionsSynchronizer _synchronizer;

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
          query: ClientAgentsRepositoryCacheSupport.defaultRefreshQuery,
        );
        await _localDataSource.saveApprovedAgents(
          userId: userId,
          query: ClientAgentsRepositoryCacheSupport.defaultRefreshQuery,
          payload: approved,
        );
        await _cacheSupport.persistHubPresenceCacheFromProfiles(
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
          query: ClientAgentsRepositoryCacheSupport.defaultRefreshQuery,
        );
        await _localDataSource.saveAccessRequests(
          userId: userId,
          query: ClientAgentsRepositoryCacheSupport.defaultRefreshQuery,
          payload: requests,
        );
      },
    );

    await _cacheSupport.readOnlineAgentIds(
      userId: userId,
      maxAge: ClientAgentsRepositoryCacheSupport.onlineStatusMaxAge,
      fallbackToOfflineCache: true,
    );
  }

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
