import 'package:colmeia/core/errors/app_failure.dart';

enum ClientAgentsActionFeedbackKind { info, success }

enum ClientAgentsPresentationMessageKey {
  clientAgentsSessionUnavailableLoad,
  clientAgentsSessionUnavailableRequest,
  clientAgentsSessionUnavailableRemove,
  clientAgentsSessionUnavailableSync,
  clientAgentsValidationTokenTooLong,
  clientAgentsRequestBlocked,
  clientAgentsRequestQueued,
  clientAgentsRequestRelinkOnly,
  clientAgentsRequestRelinkAndQueued,
  clientAgentsRemoveBlocked,
  clientAgentsRemoveQueued,
  clientAgentsRetryMissingRequestId,
  clientAgentsRetrySuccess,
  clientAgentsDiscardQueuedRequestInvalidState,
  clientAgentsDiscardQueuedRequestSuccess,
  clientAgentsNoLocalPendingToSync,
  clientAgentsSyncCooldown,
  clientAgentsSyncSuccess,
  clientAgentsApprovalPollingProgress,
  clientAgentsOwnerApproveSuccess,
  clientAgentsOwnerRejectSuccess,
  clientAgentsOwnerRevokeSuccess,
  clientAgentDetailSessionUnavailable,
  clientAgentDetailServerTokenSaved,
  clientAgentDetailServerTokenRemoved,
  clientAgentDetailProfileNameRequired,
  clientAgentDetailProfileSaved,
  clientAgentDetailRefreshFromAgentUnsupported,
  clientAgentDetailRefreshFromAgentSuccess,
}

class ClientAgentsPresentationMessage {
  const ClientAgentsPresentationMessage.failure(this.failure)
    : key = null,
      payload = const <String, Object?>{};

  const ClientAgentsPresentationMessage.key(
    this.key, {
    this.payload = const <String, Object?>{},
  }) : failure = null;

  factory ClientAgentsPresentationMessage.clientAgentsSessionUnavailableLoad() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsSessionUnavailableLoad,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRequest() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsSessionUnavailableRequest,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsSessionUnavailableRemove() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsSessionUnavailableRemove,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsSessionUnavailableSync() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsSessionUnavailableSync,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsValidationTokenTooLong({
    required int maxLength,
    required Iterable<String> agentIds,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsValidationTokenTooLong,
      payload: <String, Object?>{
        'maxLength': maxLength,
        'agentIds': _sortedStrings(agentIds),
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsRequestBlocked({
    required Iterable<String> approved,
    required Iterable<String> remotePending,
    required Iterable<String> localPending,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsRequestBlocked,
      payload: <String, Object?>{
        'approved': _sortedStrings(approved),
        'remotePending': _sortedStrings(remotePending),
        'localPending': _sortedStrings(localPending),
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsRequestQueued({
    required int queuedCount,
    required int ignoredCount,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsRequestQueued,
      payload: <String, Object?>{
        'queuedCount': queuedCount,
        'ignoredCount': ignoredCount,
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsRequestRelinkOnly({
    required int relinkedCount,
    required bool pendingCleanupOk,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsRequestRelinkOnly,
      payload: <String, Object?>{
        'relinkedCount': relinkedCount,
        'pendingCleanupOk': pendingCleanupOk,
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsRequestRelinkAndQueued({
    required int relinkedCount,
    required int queuedCount,
    required int ignoredCount,
    required bool pendingCleanupOk,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsRequestRelinkAndQueued,
      payload: <String, Object?>{
        'relinkedCount': relinkedCount,
        'queuedCount': queuedCount,
        'ignoredCount': ignoredCount,
        'pendingCleanupOk': pendingCleanupOk,
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsRemoveBlocked({
    required Iterable<String> notApproved,
    required Iterable<String> localPending,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsRemoveBlocked,
      payload: <String, Object?>{
        'notApproved': _sortedStrings(notApproved),
        'localPending': _sortedStrings(localPending),
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsRemoveQueued({
    required int queuedCount,
    required int ignoredCount,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsRemoveQueued,
      payload: <String, Object?>{
        'queuedCount': queuedCount,
        'ignoredCount': ignoredCount,
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsRetryMissingRequestId() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsRetryMissingRequestId,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsRetrySuccess() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsRetrySuccess,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsDiscardQueuedRequestInvalidState() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey
          .clientAgentsDiscardQueuedRequestInvalidState,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsDiscardQueuedRequestSuccess() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey
          .clientAgentsDiscardQueuedRequestSuccess,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsNoLocalPendingToSync() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsNoLocalPendingToSync,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsSyncCooldown({
    required int seconds,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsSyncCooldown,
      payload: <String, Object?>{'seconds': seconds},
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsSyncSuccess({
    required int syncedCount,
    required int failedCount,
    required int attemptedPendingCount,
    required bool autoTriggered,
    required bool watchingApproval,
    required int alreadyApprovedCount,
    required int debouncedCount,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsSyncSuccess,
      payload: <String, Object?>{
        'syncedCount': syncedCount,
        'failedCount': failedCount,
        'attemptedPendingCount': attemptedPendingCount,
        'autoTriggered': autoTriggered,
        'watchingApproval': watchingApproval,
        'alreadyApprovedCount': alreadyApprovedCount,
        'debouncedCount': debouncedCount,
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsApprovalPollingProgress({
    required int approvedCount,
    required int deniedCount,
    required int timedOutCount,
    required int remainingCount,
  }) {
    return ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsApprovalPollingProgress,
      payload: <String, Object?>{
        'approvedCount': approvedCount,
        'deniedCount': deniedCount,
        'timedOutCount': timedOutCount,
        'remainingCount': remainingCount,
      },
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsOwnerApproveSuccess() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsOwnerApproveSuccess,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsOwnerRejectSuccess() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsOwnerRejectSuccess,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentsOwnerRevokeSuccess() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentsOwnerRevokeSuccess,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentDetailSessionUnavailable() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentDetailSessionUnavailable,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentDetailServerTokenSaved() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentDetailServerTokenSaved,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentDetailServerTokenRemoved() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentDetailServerTokenRemoved,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentDetailProfileNameRequired() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentDetailProfileNameRequired,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentDetailProfileSaved() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey.clientAgentDetailProfileSaved,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentDetailRefreshFromAgentUnsupported() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey
          .clientAgentDetailRefreshFromAgentUnsupported,
    );
  }

  factory ClientAgentsPresentationMessage.clientAgentDetailRefreshFromAgentSuccess() {
    return const ClientAgentsPresentationMessage.key(
      ClientAgentsPresentationMessageKey
          .clientAgentDetailRefreshFromAgentSuccess,
    );
  }

  final ClientAgentsPresentationMessageKey? key;
  final Map<String, Object?> payload;
  final AppFailure? failure;
}

class ClientAgentsPresentationNotice {
  const ClientAgentsPresentationNotice({
    required this.message,
    required this.kind,
  });

  final ClientAgentsPresentationMessage message;
  final ClientAgentsActionFeedbackKind kind;
}

List<String> _sortedStrings(Iterable<String> values) {
  final sorted = values.map((value) => value.trim()).toList(growable: false)
    ..sort();
  return sorted;
}
