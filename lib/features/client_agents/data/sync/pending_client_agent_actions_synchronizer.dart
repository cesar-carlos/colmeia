import 'dart:math' show min;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/sync/pending_client_agent_actions_sync_outcome_builder.dart';
import 'package:colmeia/features/client_agents/data/sync/pending_client_agent_actions_view.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Drives one run of the offline pending-actions queue against the
/// hub.
///
/// The synchronizer instance carries the per-run state
/// ([PendingClientAgentActionsView] of the working set,
/// [PendingClientAgentActionsSyncOutcomeBuilder] for accumulated
/// results) so the repository can call [synchronize] without juggling
/// nine inline `Set<String>` variables and three persistence points.
///
/// Per-batch network errors are caught and recorded on the failed
/// agent buckets — only truly unexpected errors (data source crashes,
/// out-of-memory, etc.) propagate to the caller, which then wraps the
/// outer failure in `withRepositoryErrorMapping` for consistent
/// observability.
class PendingClientAgentActionsSynchronizer {
  PendingClientAgentActionsSynchronizer({
    required ClientAgentsRemoteDataSource remoteDataSource,
    required ClientAgentsLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final ClientAgentsRemoteDataSource _remote;
  final ClientAgentsLocalDataSource _local;

  Future<SyncPendingAgentActionsResult> synchronize({
    required String userId,
  }) async {
    final initial = await _local.readPendingActions(userId: userId);
    final recovered = await _recoverStaleSyncing(
      userId: userId,
      actions: initial,
    );

    final candidates = recovered
        .where(
          (a) =>
              a.state == PendingAgentActionState.queued ||
              a.state == PendingAgentActionState.failed,
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      return const SyncPendingAgentActionsResult();
    }

    final view = PendingClientAgentActionsView(recovered);
    final outcome = PendingClientAgentActionsSyncOutcomeBuilder();
    final candidateIds = candidates.map((a) => a.id).toSet();

    view.updateAll(
      candidateIds,
      (a) => a.copyWith(
        state: PendingAgentActionState.syncing,
        lastAttemptAt: DateTime.now(),
        attemptCount: a.attemptCount + 1,
      ),
    );
    await _local.savePendingActions(userId: userId, actions: view.toList());

    final requestActions = candidates
        .where((a) => a.type == PendingAgentActionType.requestAccess)
        .toList(growable: false);
    final removeActions = candidates
        .where((a) => a.type == PendingAgentActionType.removeAccess)
        .toList(growable: false);

    await _syncRequestAccessBatches(
      userId: userId,
      actions: requestActions,
      view: view,
      outcome: outcome,
    );

    if (removeActions.isNotEmpty) {
      await _syncRemoveAccessBatches(
        userId: userId,
        actions: removeActions,
        view: view,
        outcome: outcome,
      );
    }

    _logSummary(
      userId: userId,
      outcome: outcome,
    );

    view.removeIds(outcome.successfulActionIds);
    await _local.savePendingActions(userId: userId, actions: view.toList());

    if (outcome.successfulRemoveAccessAgentIds.isNotEmpty) {
      await Future.wait(
        outcome.successfulRemoveAccessAgentIds.map(
          (agentId) => _local.clearApprovedAgentDetail(
            userId: userId,
            agentId: agentId,
          ),
        ),
      );
    }

    return outcome.build();
  }

  /// Resets any `syncing` actions left behind by a previous run that
  /// crashed mid-flight, so the next [synchronize] picks them up again.
  Future<List<PendingAgentAction>> _recoverStaleSyncing({
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
    await _local.savePendingActions(userId: userId, actions: recovered);
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

  Future<void> _syncRequestAccessBatches({
    required String userId,
    required List<PendingAgentAction> actions,
    required PendingClientAgentActionsView view,
    required PendingClientAgentActionsSyncOutcomeBuilder outcome,
  }) async {
    if (actions.isEmpty) {
      return;
    }
    for (var start = 0; start < actions.length;) {
      final end = min(
        start + kClientAgentsRequestAccessSyncBatchSize,
        actions.length,
      );
      final chunk = actions.sublist(start, end);
      start = end;
      await _syncRequestAccessChunk(
        userId: userId,
        chunk: chunk,
        view: view,
        outcome: outcome,
      );
    }
  }

  Future<void> _syncRequestAccessChunk({
    required String userId,
    required List<PendingAgentAction> chunk,
    required PendingClientAgentActionsView view,
    required PendingClientAgentActionsSyncOutcomeBuilder outcome,
  }) async {
    final chunkAgentIds = chunk.map((a) => a.agentId).toSet();
    try {
      final response = await _remote.requestAccess(agentIds: chunkAgentIds);
      final unacknowledged = chunk
          .where((a) => !response.acknowledgesAgent(a.agentId))
          .toList(growable: false);

      if (unacknowledged.isNotEmpty) {
        const failure = ValidationFailure(
          message: 'POST /client/me/agents omitted an agent id in the body',
          userMessage:
              'The server did not confirm one or more access requests.',
        );
        for (final action in unacknowledged) {
          outcome.recordRequestAccessFailure(action.agentId);
        }
        view.updateAll(
          unacknowledged.map((a) => a.id),
          (a) => a.copyWith(
            state: PendingAgentActionState.failed,
            errorMessage: failure.displayMessage,
          ),
        );
        await _local.savePendingActions(
          userId: userId,
          actions: view.toList(),
        );
      }

      final unacknowledgedIds = unacknowledged.map((a) => a.id).toSet();
      for (final action in chunk) {
        if (unacknowledgedIds.contains(action.id)) {
          continue;
        }
        outcome.recordRequestAccessSuccess(
          actionId: action.id,
          agentId: action.agentId,
          shouldPollApproval: response.shouldPollApprovalFor(action.agentId),
          alreadyApproved: response.alreadyApproved.contains(action.agentId),
          debounced: response.debounced.contains(action.agentId),
          isNewRequest: response.newRequests.contains(action.agentId),
        );
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
              ? chunkAgentIds.join(',')
              : '${chunkAgentIds.length} ids',
          'actionType': PendingAgentActionType.requestAccess.name,
          ClientAgentsFailureUiKey.field:
              ClientAgentsFailureUiKey.syncPendingAction,
        },
      );
      outcome.recordBatchFailure(failure);
      for (final action in chunk) {
        outcome.recordRequestAccessFailure(action.agentId);
      }
      view.updateAll(
        chunk.map((a) => a.id),
        (a) => a.copyWith(
          state: PendingAgentActionState.failed,
          errorMessage: failure.displayMessage,
        ),
      );
      await _local.savePendingActions(
        userId: userId,
        actions: view.toList(),
      );
    }
  }

  Future<void> _syncRemoveAccessBatches({
    required String userId,
    required List<PendingAgentAction> actions,
    required PendingClientAgentActionsView view,
    required PendingClientAgentActionsSyncOutcomeBuilder outcome,
  }) async {
    for (var i = 0; i < actions.length;) {
      final end = min(
        i + kClientAgentsRemoveAccessSyncConcurrency,
        actions.length,
      );
      final chunk = actions.sublist(i, end);
      i = end;
      final outcomes = await Future.wait(
        chunk.map(
          (action) => _attemptRemoveAccess(userId: userId, action: action),
        ),
      );
      for (final record in outcomes) {
        final action = record.$1;
        final failure = record.$2;
        if (failure == null) {
          outcome.recordRemoveAccessSuccess(
            actionId: action.id,
            agentId: action.agentId,
          );
        } else {
          outcome
            ..recordRemoveAccessFailure(action.agentId)
            ..recordBatchFailure(failure);
          view.update(
            action.id,
            (a) => a.copyWith(
              state: PendingAgentActionState.failed,
              errorMessage: failure.displayMessage,
            ),
          );
        }
      }
    }
    await _local.savePendingActions(userId: userId, actions: view.toList());
    AppLogger.info(
      'Synced client agent remove-access operations',
      context: <String, Object?>{
        'operation': 'syncPendingActions',
        'userId': userId,
        'count': actions.length,
        'ok': outcome.successfulRemoveAccessCount,
        'failed': outcome.failedRemoveAccessCount,
      },
    );
  }

  Future<(PendingAgentAction, AppFailure?)> _attemptRemoveAccess({
    required String userId,
    required PendingAgentAction action,
  }) async {
    try {
      await _remote.removeApprovedAgentById(action.agentId);
      return (action, null);
    } on Object catch (error, stackTrace) {
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to sync agent action',
        fallbackUserMessage: 'Could not sync the change for this agent.',
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
  }

  void _logSummary({
    required String userId,
    required PendingClientAgentActionsSyncOutcomeBuilder outcome,
  }) {
    AppLogger.info(
      'Client agents pending sync summary',
      context: <String, Object?>{
        'operation': 'syncPendingActions',
        'userId': userId,
        'requestAccessOk': outcome.successfulRequestAccessCount,
        'requestAccessFailed': outcome.failedRequestAccessCount,
        'removeAccessOk': outcome.successfulRemoveAccessCount,
        'removeAccessFailed': outcome.failedRemoveAccessCount,
        'approvalPollIds': outcome.requestAccessPollCount,
        'newRequestsIds': outcome.requestAccessNewRequestsCount,
      },
    );
  }
}
