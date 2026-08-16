import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';

/// Surface the sync coordinator needs from its owner controller.
abstract interface class ClientAgentsSyncHost {
  bool get isDisposed;

  bool get isBusy;

  String? get currentUserId;

  List<PendingAgentAction> get pendingActionsSnapshot;

  void setSyncingPending({required bool value});

  void setMutating({required bool value});

  void setActionError(ClientAgentsPresentationMessage? error);

  void clearActionFeedback();

  void setActionFeedback({
    required ClientAgentsPresentationMessage message,
    required ClientAgentsActionFeedbackKind kind,
  });

  ClientAgentsPresentationMessage? consumeResult<T extends Object>({
    required AppResult<T> result,
    required String operation,
    void Function(T value)? onSuccess,
  });

  ClientAgentsPresentationMessage? get actionError;

  Future<void> refreshAfterMutation({required String userId});

  Future<void> hydrateApprovedAgentsInMemory({
    required String userId,
    required Iterable<String> agentIds,
  });

  void invalidateTargetResolution({required String userId});

  void startApprovalPolling({
    required String userId,
    required Set<String> agentIds,
  });

  void pushLocalTokensAfterApproval({
    required String userId,
    required Iterable<String> agentIds,
  });

  void notifySyncChanged();

  Future<T> runPendingMutationSerialized<T>(
    Future<T> Function() action, {
    bool resetBusyFlags = true,
  });
}

/// Owns pending-action sync, `Retry-After` cooldown for sync, and the
/// auto-sync scheduler that fires after enqueue when the gate is open.
class ClientAgentsSyncCoordinator {
  ClientAgentsSyncCoordinator({
    required this._host,
    required this._syncPendingActionsUseCase,
    RetryAfterGate? syncRetryAfterGate,
  }) : _syncRetryAfterGate = syncRetryAfterGate ?? RetryAfterGate(),
       _ownsSyncRetryAfterGate = syncRetryAfterGate == null {
    _syncRetryAfterGate.addListener(_handleSyncRetryAfterGateChanged);
  }

  final ClientAgentsSyncHost _host;
  final SyncPendingClientAgentActionsUseCase _syncPendingActionsUseCase;
  final RetryAfterGate _syncRetryAfterGate;
  final bool _ownsSyncRetryAfterGate;

  Duration? get syncRetryAfter => _syncRetryAfterGate.remaining;
  bool get isSyncOnCooldown => !_syncRetryAfterGate.isOpen;

  void dispose() {
    _syncRetryAfterGate.removeListener(_handleSyncRetryAfterGateChanged);
    if (_ownsSyncRetryAfterGate) {
      _syncRetryAfterGate.dispose();
    }
  }

  Future<void> syncPending({bool autoTriggered = false}) async {
    final userId = _host.currentUserId;
    if (userId == null || userId.isEmpty) {
      _host
        ..setActionError(
          ClientAgentsPresentationMessage.clientAgentsSessionUnavailableSync(),
        )
        ..notifySyncChanged();
      return;
    }

    if (!_syncRetryAfterGate.isOpen) {
      if (!autoTriggered) {
        _host
          ..setActionError(
            ClientAgentsPresentationMessage.clientAgentsSyncCooldown(
              seconds: _remainingRetryAfterSeconds(
                _syncRetryAfterGate.remaining,
              ),
            ),
          )
          ..notifySyncChanged();
      }
      return;
    }

    await _host.runPendingMutationSerialized(() async {
      if (_host.isDisposed) {
        return;
      }

      final pendingCount = _host.pendingActionsSnapshot
          .where(
            (action) =>
                action.state == PendingAgentActionState.queued ||
                action.state == PendingAgentActionState.failed,
          )
          .length;
      if (pendingCount == 0) {
        if (!autoTriggered) {
          _host
            ..setActionFeedback(
              message:
                  ClientAgentsPresentationMessage.clientAgentsNoLocalPendingToSync(),
              kind: ClientAgentsActionFeedbackKind.info,
            )
            ..notifySyncChanged();
        }
        return;
      }

      if (autoTriggered) {
        _host
          ..setSyncingPending(value: true)
          ..setMutating(value: true)
          ..setActionError(null)
          ..notifySyncChanged();
      } else {
        _host
          ..setSyncingPending(value: true)
          ..setMutating(value: true)
          ..setActionError(null)
          ..clearActionFeedback()
          ..notifySyncChanged();
      }

      final syncResult = await _syncPendingActionsUseCase(userId: userId);
      syncResult.fold(
        (value) {
          AppLogger.info(
            'Client agents pending sync outcome',
            context: <String, Object?>{
              'operation': 'syncPendingClientAgentActions',
              'pollIds': value.requestAccessPollAgentIds.length,
              'alreadyApproved':
                  value.requestAccessAlreadyApprovedAgentIds.length,
              'debounced': value.requestAccessDebouncedAgentIds.length,
              'newRequests': value.requestAccessNewRequestsAgentIds.length,
            },
          );
        },
        (_) {},
      );
      final requestAccessPollAgentIds = syncResult.fold(
        (value) => value.requestAccessPollAgentIds,
        (_) => const <String>{},
      );
      final requestAccessAlreadyApprovedOnSync = syncResult.fold(
        (value) => value.requestAccessAlreadyApprovedAgentIds,
        (_) => const <String>{},
      );
      final requestAccessDebouncedOnSync = syncResult.fold(
        (value) => value.requestAccessDebouncedAgentIds,
        (_) => const <String>{},
      );
      _host.setActionError(
        _host.consumeResult(
          result: syncResult,
          operation: 'syncPendingClientAgentActions',
        ),
      );
      _maybeArmSyncRetryGateFromResult(syncResult);
      await _host.refreshAfterMutation(userId: userId);
      if (_host.isDisposed) {
        return;
      }
      if (_host.actionError == null &&
          requestAccessAlreadyApprovedOnSync.isNotEmpty) {
        await _host.hydrateApprovedAgentsInMemory(
          userId: userId,
          agentIds: requestAccessAlreadyApprovedOnSync,
        );
        _host.invalidateTargetResolution(userId: userId);
      }
      if (_host.actionError == null) {
        final outcome = syncResult.getOrNull();
        if (outcome != null) {
          _host.setActionFeedback(
            message: ClientAgentsPresentationMessage.clientAgentsSyncSuccess(
              syncedCount: outcome.successfulActionCount,
              failedCount: outcome.failedActionCount,
              attemptedPendingCount: pendingCount,
              autoTriggered: autoTriggered,
              watchingApproval: requestAccessPollAgentIds.isNotEmpty,
              alreadyApprovedCount: requestAccessAlreadyApprovedOnSync.length,
              debouncedCount: requestAccessDebouncedOnSync.length,
            ),
            kind: ClientAgentsActionFeedbackKind.success,
          );
          if (outcome.successfulRemoveAccessAgentIds.isNotEmpty) {
            _host.invalidateTargetResolution(userId: userId);
          }
        }
        if (requestAccessAlreadyApprovedOnSync.isNotEmpty) {
          _host.pushLocalTokensAfterApproval(
            userId: userId,
            agentIds: requestAccessAlreadyApprovedOnSync,
          );
        }
        _host
          ..setSyncingPending(value: false)
          ..setMutating(value: false)
          ..startApprovalPolling(
            userId: userId,
            agentIds: requestAccessPollAgentIds,
          )
          ..notifySyncChanged();
      }
    });
  }

  void scheduleAutoSyncIfNeeded() {
    if (_host.isBusy || !_syncRetryAfterGate.isOpen) {
      return;
    }
    final hasPendingSync = _host.pendingActionsSnapshot.any(
      (action) =>
          action.state == PendingAgentActionState.queued ||
          action.state == PendingAgentActionState.failed,
    );
    if (!hasPendingSync) {
      return;
    }
    unawaited(syncPending(autoTriggered: true));
  }

  void _handleSyncRetryAfterGateChanged() {
    if (_host.isDisposed) {
      return;
    }
    _host.notifySyncChanged();
    if (_syncRetryAfterGate.isOpen) {
      scheduleAutoSyncIfNeeded();
    }
  }

  void _maybeArmSyncRetryGateFromResult(
    AppResult<SyncPendingAgentActionsResult> result,
  ) {
    result.fold(
      (value) {
        final retryAfter = value.retryAfter;
        if (retryAfter != null) {
          _syncRetryAfterGate.arm(retryAfter);
        }
      },
      (_) {},
    );
    final retryAfter = _retryAfterFromResult(result);
    if (retryAfter != null) {
      _syncRetryAfterGate.arm(retryAfter);
    }
  }

  Duration? _retryAfterFromResult<T extends Object>(AppResult<T> result) {
    final failure = result.exceptionOrNull();
    if (failure is NetworkFailure) {
      return failure.retryAfter;
    }
    return null;
  }

  int _remainingRetryAfterSeconds(Duration? remaining) {
    return (remaining?.inSeconds ?? 0).clamp(1, 86400);
  }
}
