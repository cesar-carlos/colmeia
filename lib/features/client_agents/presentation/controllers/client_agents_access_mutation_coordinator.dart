import 'dart:math' show min;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/request_access_submission_snapshot.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:result_dart/result_dart.dart' show Unit;

/// Surface the [ClientAgentsAccessMutationCoordinator] needs from its owner to
/// read list snapshots and apply mutation side effects.
abstract interface class ClientAgentsAccessMutationHost {
  bool get isDisposed;

  PaginatedResult<ClientAgent>? get approvedAgentsSnapshot;

  PaginatedResult<ClientAgentAccessRequest>? get accessRequestsSnapshot;

  List<PendingAgentAction> get pendingActionsSnapshot;

  void setActionError(ClientAgentsPresentationMessage? error);

  void clearActionFeedback();

  void setActionFeedback({
    required ClientAgentsPresentationMessage message,
    required ClientAgentsActionFeedbackKind kind,
  });

  void replaceApprovedAgents(PaginatedResult<ClientAgent> value);

  void upsertApprovedAgentsInMemory(List<ClientAgent> agents);

  void replacePendingActions(List<PendingAgentAction> actions);

  void setPendingActionsError(ClientAgentsPresentationMessage? error);

  void invalidateTargetResolution({required String userId});

  void scheduleLocalTokenServerFlush({
    required String userId,
    required Iterable<String> agentIds,
  });

  void notifyMutationChanged();

  ClientAgentsPresentationMessage? consumeResult<T extends Object>({
    required AppResult<T> result,
    required String operation,
    void Function(T value)? onSuccess,
  });
}

/// Owns request/remove access classification, queueing and user feedback for
/// client-agent mutations. The controller remains the state owner and
/// serializes calls through its mutation queue.
class ClientAgentsAccessMutationCoordinator {
  ClientAgentsAccessMutationCoordinator({
    required ClientAgentsAccessMutationHost host,
    required LoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase,
    required QueueClientAgentRequestAccessUseCase queueRequestAccessUseCase,
    required QueueClientAgentRemoveAccessUseCase queueRemoveAccessUseCase,
    required ProbeClientApprovedAgentUseCase probeClientApprovedAgentUseCase,
    required DiscardQueuedClientAgentRequestAccessUseCase
    discardQueuedClientAgentRequestAccessUseCase,
    required ReadPendingClientAgentActionsUseCase readPendingActionsUseCase,
    int probeConcurrency = 4,
  }) : _host = host,
       _loadApprovedAgentsUseCase = loadApprovedAgentsUseCase,
       _queueRequestAccessUseCase = queueRequestAccessUseCase,
       _queueRemoveAccessUseCase = queueRemoveAccessUseCase,
       _probeClientApprovedAgentUseCase = probeClientApprovedAgentUseCase,
       _discardQueuedClientAgentRequestAccessUseCase =
           discardQueuedClientAgentRequestAccessUseCase,
       _readPendingActionsUseCase = readPendingActionsUseCase,
       _probeConcurrency = probeConcurrency;

  final ClientAgentsAccessMutationHost _host;
  final LoadClientApprovedAgentsUseCase _loadApprovedAgentsUseCase;
  final QueueClientAgentRequestAccessUseCase _queueRequestAccessUseCase;
  final QueueClientAgentRemoveAccessUseCase _queueRemoveAccessUseCase;
  final ProbeClientApprovedAgentUseCase _probeClientApprovedAgentUseCase;
  final DiscardQueuedClientAgentRequestAccessUseCase
  _discardQueuedClientAgentRequestAccessUseCase;
  final ReadPendingClientAgentActionsUseCase _readPendingActionsUseCase;
  final int _probeConcurrency;

  Future<bool> requestAccess({
    required String userId,
    required Set<String> agentIds,
    Future<void> Function(RequestAccessSubmissionSnapshot snapshot)? onResolved,
    void Function(AppResult<Unit> queueResult)? onQueueResult,
  }) async {
    if (agentIds.isEmpty || _host.isDisposed) {
      return false;
    }

    _host.setActionError(null);
    _host.clearActionFeedback();

    final ids = agentIds.toList(growable: false);
    final relinkedById = <String, ClientAgent>{};
    final idsForClassification = <String>{};
    var probeFailureFallbackCount = 0;
    var authAborted = false;

    for (var i = 0; i < ids.length; i += _probeConcurrency) {
      final upper = min(i + _probeConcurrency, ids.length);
      final chunk = ids.sublist(i, upper);
      final chunkOutcomes = await Future.wait(
        chunk.map((agentId) async {
          final probeResult = await _probeClientApprovedAgentUseCase(
            userId: userId,
            agentId: agentId,
          );
          return (agentId, probeResult);
        }),
      );
      if (_host.isDisposed) {
        return false;
      }

      for (final record in chunkOutcomes) {
        record.$2.fold(
          (outcome) {
            final agent = outcome.agent;
            if (outcome.isLinked && agent != null) {
              relinkedById[agent.agentId] = agent;
            } else {
              idsForClassification.add(record.$1);
            }
          },
          (failure) {
            final authMessage = _probeAuthBlockingUserMessage(failure);
            if (authMessage != null) {
              _host.setActionError(authMessage);
              authAborted = true;
              return;
            }
            probeFailureFallbackCount++;
            idsForClassification.add(record.$1);
          },
        );
        if (authAborted) {
          break;
        }
      }
      if (authAborted) {
        break;
      }
    }

    if (_host.isDisposed || authAborted) {
      if (authAborted) {
        await _reloadPendingAfterEnqueue(userId: userId);
      }
      return false;
    }

    final relinkedAgents = relinkedById.values.toList(growable: false);
    var pendingCleanupOk = true;
    if (relinkedAgents.isNotEmpty) {
      pendingCleanupOk = await _discardRelinkedPendingWithRetry(
        userId: userId,
        agentIds: relinkedById.keys.toSet(),
      );
      if (_host.isDisposed) {
        return false;
      }
      await _reloadApprovedAgentsCacheAfterRelink(
        userId: userId,
        fallbackAgents: relinkedAgents,
      );
      if (_host.isDisposed) {
        return false;
      }
      _host.invalidateTargetResolution(userId: userId);
      _host.scheduleLocalTokenServerFlush(
        userId: userId,
        agentIds: relinkedById.keys,
      );
    }

    AppLogger.info(
      'Client agents request access preflight completed',
      context: <String, Object?>{
        'relinkedCount': relinkedById.length,
        'classificationCount': idsForClassification.length,
        'probeFailureFallbackCount': probeFailureFallbackCount,
        'pendingCleanupOk': pendingCleanupOk,
      },
    );

    final classification = _classifyRequestAgentIds(idsForClassification);
    if (classification.allowed.isEmpty) {
      if (relinkedAgents.isEmpty) {
        _host.setActionError(_buildBlockedRequestMessage(classification));
      } else {
        _host.setActionFeedback(
          message: ClientAgentsPresentationMessage.clientAgentsRequestRelinkOnly(
            relinkedCount: relinkedAgents.length,
            pendingCleanupOk: pendingCleanupOk,
          ),
          kind: ClientAgentsActionFeedbackKind.success,
        );
        if (onResolved != null) {
          await onResolved(
            RequestAccessSubmissionSnapshot(
              relinkedAgentIds: relinkedById.keys.toSet(),
              queuedAgentIds: const <String>{},
            ),
          );
        }
      }
      await _reloadPendingAfterEnqueue(userId: userId);
      return relinkedAgents.isNotEmpty;
    }

    final queueResult = await _queueRequestAccessUseCase(
      userId: userId,
      agentIds: classification.allowed,
    );
    if (_host.isDisposed) {
      return false;
    }
    onQueueResult?.call(queueResult);
    final queueError = _host.consumeResult(
      result: queueResult,
      operation: 'queueClientAgentRequestAccess',
    );
    _host.setActionError(queueError);
    if (queueError == null) {
      if (relinkedAgents.isEmpty) {
        _host.setActionFeedback(
          message: _buildQueuedRequestMessage(classification),
          kind: ClientAgentsActionFeedbackKind.info,
        );
      } else {
        _host.setActionFeedback(
          message:
              ClientAgentsPresentationMessage.clientAgentsRequestRelinkAndQueued(
                relinkedCount: relinkedAgents.length,
                queuedCount: classification.allowed.length,
                ignoredCount:
                    classification.approved.length +
                    classification.remotePending.length +
                    classification.localPending.length,
                pendingCleanupOk: pendingCleanupOk,
              ),
          kind: ClientAgentsActionFeedbackKind.info,
        );
      }
      if (onResolved != null) {
        await onResolved(
          RequestAccessSubmissionSnapshot(
            relinkedAgentIds: relinkedById.keys.toSet(),
            queuedAgentIds: classification.allowed,
          ),
        );
      }
    }
    await _reloadPendingAfterEnqueue(userId: userId);
    return queueError == null;
  }

  Future<void> removeAccess({
    required String userId,
    required Set<String> agentIds,
  }) async {
    if (agentIds.isEmpty || _host.isDisposed) {
      return;
    }

    _host.setActionError(null);
    _host.clearActionFeedback();

    final classification = _classifyRemoveAgentIds(agentIds);
    if (classification.allowed.isEmpty) {
      _host.setActionError(_buildBlockedRemoveMessage(classification));
      _host.notifyMutationChanged();
      return;
    }

    final queueResult = await _queueRemoveAccessUseCase(
      userId: userId,
      agentIds: classification.allowed,
    );
    if (_host.isDisposed) {
      return;
    }
    _host.setActionError(
      _host.consumeResult(
        result: queueResult,
        operation: 'queueClientAgentRemoveAccess',
      ),
    );
    if (queueResult.isSuccess()) {
      _host.setActionFeedback(
        message: _buildQueuedRemoveMessage(classification),
        kind: ClientAgentsActionFeedbackKind.info,
      );
    }
    await _reloadPendingAfterEnqueue(userId: userId);
  }

  ClientAgentsPresentationMessage? _probeAuthBlockingUserMessage(
    AppFailure failure,
  ) {
    if (failure is SessionFailure) {
      return ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest();
    }
    if (failure is AuthorizationFailure) {
      if (isBlockedAccountFailure(failure)) {
        return ClientAgentsPresentationMessage.failure(failure);
      }
      return ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest();
    }
    return null;
  }

  Future<bool> _discardRelinkedPendingWithRetry({
    required String userId,
    required Set<String> agentIds,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final discardResult = await _discardQueuedClientAgentRequestAccessUseCase(
        userId: userId,
        agentIds: agentIds,
      );
      if (_host.isDisposed) {
        return false;
      }
      if (discardResult.isSuccess()) {
        return true;
      }
      discardResult.fold((_) {}, (failure) {
        AppLogger.warning(
          'discardQueuedClientAgentRequestAccess failed',
          context: <String, Object?>{
            'operation': 'discardQueuedClientAgentRequestAccess',
            'attempt': attempt + 1,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      });
    }
    return false;
  }

  Future<void> _reloadApprovedAgentsCacheAfterRelink({
    required String userId,
    required List<ClientAgent> fallbackAgents,
  }) async {
    const query = PaginatedQuery(pageSize: kClientAgentsListPageSize);
    final result = await _loadApprovedAgentsUseCase(
      userId: userId,
      query: query,
      refresh: true,
    );
    if (_host.isDisposed) {
      return;
    }
    result.fold(
      (value) {
        _host.replaceApprovedAgents(value);
        _host.upsertApprovedAgentsInMemory(fallbackAgents);
      },
      (failure) {
        AppLogger.warning(
          'Approved agents refresh after relink failed; merged local list',
          context: <String, Object?>{
            'operation': 'reloadApprovedAgentsAfterRelink',
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
        _host.upsertApprovedAgentsInMemory(fallbackAgents);
      },
    );
  }

  Future<void> _reloadPendingAfterEnqueue({
    required String userId,
  }) async {
    final pendingResult = await _readPendingActionsUseCase(userId: userId);
    if (_host.isDisposed) {
      return;
    }
    _host.setPendingActionsError(
      _host.consumeResult(
        result: pendingResult,
        onSuccess: _host.replacePendingActions,
        operation: 'readPendingClientAgentActions',
      ),
    );
    _host.notifyMutationChanged();
  }

  ({
    Set<String> allowed,
    Set<String> approved,
    Set<String> remotePending,
    Set<String> localPending,
  })
  _classifyRequestAgentIds(Set<String> agentIds) {
    final approved = _approvedAgentIds().intersection(agentIds);
    final remotePending = _remotePendingRequestIds().intersection(agentIds);
    final localPending = _localPendingRequestIds().intersection(agentIds);
    final blocked = <String>{...approved, ...remotePending, ...localPending};
    final allowed = agentIds.difference(blocked);
    return (
      allowed: allowed,
      approved: approved,
      remotePending: remotePending,
      localPending: localPending,
    );
  }

  ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
  _classifyRemoveAgentIds(Set<String> agentIds) {
    final approved = _approvedAgentIds();
    final localPending = _localPendingRemoveIds().intersection(agentIds);
    final notApproved = agentIds.difference(approved);
    final blocked = <String>{...notApproved, ...localPending};
    final allowed = agentIds.difference(blocked);
    return (
      allowed: allowed,
      notApproved: notApproved,
      localPending: localPending,
    );
  }

  Set<String> _approvedAgentIds() {
    return _host.approvedAgentsSnapshot?.items
            .map((agent) => agent.agentId)
            .toSet() ??
        const <String>{};
  }

  Set<String> _remotePendingRequestIds() {
    return _host.accessRequestsSnapshot?.items
            .where(
              (request) => request.status == AgentAccessRequestStatus.pending,
            )
            .map((request) => request.agentId)
            .toSet() ??
        const <String>{};
  }

  Set<String> _localPendingRequestIds() {
    return _host.pendingActionsSnapshot
        .where(
          (action) =>
              action.type == PendingAgentActionType.requestAccess &&
              action.state != PendingAgentActionState.synced,
        )
        .map((action) => action.agentId)
        .toSet();
  }

  Set<String> _localPendingRemoveIds() {
    return _host.pendingActionsSnapshot
        .where(
          (action) =>
              action.type == PendingAgentActionType.removeAccess &&
              action.state != PendingAgentActionState.synced,
        )
        .map((action) => action.agentId)
        .toSet();
  }

  ClientAgentsPresentationMessage _buildBlockedRequestMessage(
    ({
      Set<String> allowed,
      Set<String> approved,
      Set<String> remotePending,
      Set<String> localPending,
    })
    classification,
  ) {
    return ClientAgentsPresentationMessage.clientAgentsRequestBlocked(
      approved: classification.approved,
      remotePending: classification.remotePending,
      localPending: classification.localPending,
    );
  }

  ClientAgentsPresentationMessage _buildQueuedRequestMessage(
    ({
      Set<String> allowed,
      Set<String> approved,
      Set<String> remotePending,
      Set<String> localPending,
    })
    classification,
  ) {
    return ClientAgentsPresentationMessage.clientAgentsRequestQueued(
      queuedCount: classification.allowed.length,
      ignoredCount:
          classification.approved.length +
          classification.remotePending.length +
          classification.localPending.length,
    );
  }

  ClientAgentsPresentationMessage _buildBlockedRemoveMessage(
    ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
    classification,
  ) {
    return ClientAgentsPresentationMessage.clientAgentsRemoveBlocked(
      notApproved: classification.notApproved,
      localPending: classification.localPending,
    );
  }

  ClientAgentsPresentationMessage _buildQueuedRemoveMessage(
    ({Set<String> allowed, Set<String> notApproved, Set<String> localPending})
    classification,
  ) {
    return ClientAgentsPresentationMessage.clientAgentsRemoveQueued(
      queuedCount: classification.allowed.length,
      ignoredCount:
          classification.notApproved.length +
          classification.localPending.length,
    );
  }
}
