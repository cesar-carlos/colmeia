import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/retry_client_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';

/// Surface for retry/discard access-request actions that sit outside the
/// queue/remove mutation coordinator.
abstract interface class ClientAgentsAccessRequestActionsHost {
  bool get isDisposed;

  String? get currentUserId;

  List<PendingAgentAction> get pendingActionsSnapshot;

  void setActionError(ClientAgentsPresentationMessage? error);

  void clearActionFeedback();

  void setActionFeedback({
    required ClientAgentsPresentationMessage message,
    required ClientAgentsActionFeedbackKind kind,
  });

  void setMutating({required bool value});

  void notifyActionsChanged();

  ClientAgentsPresentationMessage? consumeResult<T extends Object>({
    required AppResult<T> result,
    required String operation,
  });

  Future<void> refreshAfterMutation({required String userId});

  Future<void> persistLocalClientTokenDraftLine({
    required String agentIdRaw,
    required String clientTokenRaw,
  });

  void startApprovalPolling({
    required String userId,
    required Set<String> agentIds,
  });
}

/// Owns retry and discard flows for client access requests.
class ClientAgentsAccessRequestActionsCoordinator {
  ClientAgentsAccessRequestActionsCoordinator({
    required this._host,
    required this._retryClientAccessRequestUseCase,
    required this._discardQueuedClientAgentRequestAccessUseCase,
  });

  final ClientAgentsAccessRequestActionsHost _host;
  final RetryClientAccessRequestUseCase _retryClientAccessRequestUseCase;
  final DiscardQueuedClientAgentRequestAccessUseCase
  _discardQueuedClientAgentRequestAccessUseCase;

  Future<void> retryAccessRequest({
    required ClientAgentAccessRequest request,
  }) async {
    final requestId = request.requestId?.trim();
    if (requestId == null || requestId.isEmpty) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsRetryMissingRequestId(),
        )
        ..notifyActionsChanged();
      return;
    }
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest(),
        )
        ..notifyActionsChanged();
      return;
    }

    if (_host.isDisposed) {
      return;
    }
    _host
      ..setMutating(value: true)
      ..setActionError(null)
      ..clearActionFeedback()
      ..notifyActionsChanged();

    final retryResult = await _retryClientAccessRequestUseCase(
      userId: userId,
      requestId: requestId,
    );
    final retryError = _host.consumeResult(
      result: retryResult,
      operation: 'retryClientAccessRequest',
    );
    _host.setActionError(retryError);
    await _host.refreshAfterMutation(userId: userId);
    if (retryError == null) {
      _host
        ..setActionFeedback(
          message: ClientAgentsPresentationMessage.clientAgentsRetrySuccess(),
          kind: ClientAgentsActionFeedbackKind.info,
        )
        ..setMutating(value: false)
        ..startApprovalPolling(
          userId: userId,
          agentIds: <String>{request.agentId},
        );
    }
    _host.notifyActionsChanged();
  }

  Future<void> discardQueuedRequestAccess({
    required PendingAgentAction action,
  }) async {
    if (_host.isDisposed) {
      return;
    }
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest(),
        )
        ..notifyActionsChanged();
      return;
    }
    final agentId = action.agentId.trim();
    if (!_matchesDiscardableLocalRequestAccess(action, agentId)) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsDiscardQueuedRequestInvalidState(),
        )
        ..notifyActionsChanged();
      return;
    }
    final beforeCount = _host.pendingActionsSnapshot
        .where((a) => _matchesDiscardableLocalRequestAccess(a, agentId))
        .length;
    if (beforeCount == 0) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsDiscardQueuedRequestInvalidState(),
        )
        ..notifyActionsChanged();
      return;
    }

    _host
      ..setMutating(value: true)
      ..setActionError(null)
      ..clearActionFeedback()
      ..notifyActionsChanged();

    final discardResult = await _discardQueuedClientAgentRequestAccessUseCase(
      userId: userId,
      agentIds: <String>{agentId},
    );
    final discardError = _host.consumeResult(
      result: discardResult,
      operation: 'discardQueuedClientAgentRequestAccess',
    );
    _host.setActionError(discardError);
    await _host.refreshAfterMutation(userId: userId);
    if (discardError == null) {
      final afterCount = _host.pendingActionsSnapshot
          .where((a) => _matchesDiscardableLocalRequestAccess(a, agentId))
          .length;
      if (beforeCount > afterCount) {
        await _host.persistLocalClientTokenDraftLine(
          agentIdRaw: agentId,
          clientTokenRaw: '',
        );
        _host.setActionFeedback(
          message:
              ClientAgentsPresentationMessage.clientAgentsDiscardQueuedRequestSuccess(),
          kind: ClientAgentsActionFeedbackKind.info,
        );
      }
    }
    _host.notifyActionsChanged();
  }

  bool _matchesDiscardableLocalRequestAccess(
    PendingAgentAction action,
    String trimmedAgentId,
  ) {
    return action.agentId.trim() == trimmedAgentId &&
        action.type == PendingAgentActionType.requestAccess &&
        (action.state == PendingAgentActionState.queued ||
            action.state == PendingAgentActionState.failed);
  }
}
