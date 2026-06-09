import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/l10n/app_localizations.dart';

String localizeClientAgentsPresentationMessage(
  ClientAgentsPresentationMessage message,
  AppLocalizations l10n,
) {
  final failure = message.failure;
  if (failure != null) {
    return clientAgentsFailureUserMessage(failure, l10n);
  }

  final key = message.key;
  if (key == null) {
    return '';
  }

  return switch (key) {
    ClientAgentsPresentationMessageKey.clientAgentsSessionUnavailableLoad =>
      l10n.clientAgentsSessionUnavailableLoad,
    ClientAgentsPresentationMessageKey.clientAgentsSessionUnavailableRequest =>
      l10n.clientAgentsSessionUnavailableRequest,
    ClientAgentsPresentationMessageKey.clientAgentsSessionUnavailableRemove =>
      l10n.clientAgentsSessionUnavailableRemove,
    ClientAgentsPresentationMessageKey.clientAgentsSessionUnavailableSync =>
      l10n.clientAgentsSessionUnavailableSync,
    ClientAgentsPresentationMessageKey.clientAgentsValidationTokenTooLong =>
      l10n.clientAgentsValidationTokenTooLong(
        _requiredInt(message, 'maxLength'),
        _requiredStrings(message, 'agentIds').join(', '),
      ),
    ClientAgentsPresentationMessageKey.clientAgentsRequestBlocked =>
      _localizeRequestBlocked(message, l10n),
    ClientAgentsPresentationMessageKey.clientAgentsRequestQueued =>
      _localizeRequestQueued(message, l10n),
    ClientAgentsPresentationMessageKey.clientAgentsRequestRelinkOnly =>
      _withPendingCleanupNote(
        relinkMessage: _relinkFeedbackMessage(
          l10n,
          _requiredInt(message, 'relinkedCount'),
        ),
        pendingCleanupOk: _requiredBool(message, 'pendingCleanupOk'),
        l10n: l10n,
      ),
    ClientAgentsPresentationMessageKey.clientAgentsRequestRelinkAndQueued =>
      _withPendingCleanupNote(
        relinkMessage: l10n.clientAgentsRequestRelinkAndQueued(
          _relinkFeedbackMessage(l10n, _requiredInt(message, 'relinkedCount')),
          _requestQueuedMessage(
            l10n,
            queuedCount: _requiredInt(message, 'queuedCount'),
            ignoredCount: _requiredInt(message, 'ignoredCount'),
          ),
        ),
        pendingCleanupOk: _requiredBool(message, 'pendingCleanupOk'),
        l10n: l10n,
      ),
    ClientAgentsPresentationMessageKey.clientAgentsRemoveBlocked =>
      _localizeRemoveBlocked(message, l10n),
    ClientAgentsPresentationMessageKey.clientAgentsRemoveQueued =>
      _removeQueuedMessage(
        l10n,
        queuedCount: _requiredInt(message, 'queuedCount'),
        ignoredCount: _requiredInt(message, 'ignoredCount'),
      ),
    ClientAgentsPresentationMessageKey.clientAgentsRetryMissingRequestId =>
      l10n.clientAgentsRetryMissingRequestId,
    ClientAgentsPresentationMessageKey.clientAgentsRetrySuccess =>
      l10n.clientAgentsRetrySuccess,
    ClientAgentsPresentationMessageKey
        .clientAgentsDiscardQueuedRequestInvalidState =>
      l10n.clientAgentsDiscardQueuedRequestInvalidState,
    ClientAgentsPresentationMessageKey
        .clientAgentsDiscardQueuedRequestSuccess =>
      l10n.clientAgentsDiscardQueuedRequestSuccess,
    ClientAgentsPresentationMessageKey.clientAgentsNoLocalPendingToSync =>
      l10n.clientAgentsNoLocalPendingToSync,
    ClientAgentsPresentationMessageKey.clientAgentsSyncCooldown =>
      l10n.clientAgentsSyncRetryAfterCountdown(
        _requiredInt(message, 'seconds'),
      ),
    ClientAgentsPresentationMessageKey.clientAgentsSyncSuccess =>
      _localizeSyncSuccess(message, l10n),
    ClientAgentsPresentationMessageKey.clientAgentsApprovalPollingProgress =>
      _localizeApprovalPollingProgress(message, l10n),
    ClientAgentsPresentationMessageKey.clientAgentsLocalTokenServerFlushFailed =>
      _localizeLocalTokenServerFlushFailed(message, l10n),
    ClientAgentsPresentationMessageKey.clientAgentsOwnerApproveSuccess =>
      l10n.clientAgentsOwnerApproveSuccess,
    ClientAgentsPresentationMessageKey.clientAgentsOwnerRejectSuccess =>
      l10n.clientAgentsOwnerRejectSuccess,
    ClientAgentsPresentationMessageKey.clientAgentsOwnerRevokeSuccess =>
      l10n.clientAgentsOwnerRevokeSuccess,
    ClientAgentsPresentationMessageKey.clientAgentDetailSessionUnavailable =>
      l10n.clientAgentDetailSessionUnavailable,
    ClientAgentsPresentationMessageKey.clientAgentDetailServerTokenSaved =>
      l10n.clientAgentDetailServerTokenSaved,
    ClientAgentsPresentationMessageKey.clientAgentDetailServerTokenRemoved =>
      l10n.clientAgentDetailServerTokenRemoved,
    ClientAgentsPresentationMessageKey.clientAgentDetailProfileNameRequired =>
      l10n.clientAgentDetailProfileNameRequired,
    ClientAgentsPresentationMessageKey.clientAgentDetailProfileSaved =>
      l10n.clientAgentDetailProfileSaved,
    ClientAgentsPresentationMessageKey
        .clientAgentDetailRefreshFromAgentUnsupported =>
      l10n.clientAgentDetailRefreshFromAgentUnsupported,
    ClientAgentsPresentationMessageKey
        .clientAgentDetailRefreshFromAgentSuccess =>
      l10n.clientAgentDetailRefreshFromAgentSuccess,
  };
}

String _localizeRequestBlocked(
  ClientAgentsPresentationMessage message,
  AppLocalizations l10n,
) {
  final approved = _requiredStrings(message, 'approved');
  final remotePending = _requiredStrings(message, 'remotePending');
  final localPending = _requiredStrings(message, 'localPending');
  final parts = <String>[
    if (approved.isNotEmpty)
      l10n.clientAgentsRequestBlockedAlreadyApproved(approved.join(', ')),
    if (remotePending.isNotEmpty)
      l10n.clientAgentsRequestBlockedAlreadyReview(remotePending.join(', ')),
    if (localPending.isNotEmpty)
      l10n.clientAgentsRequestBlockedAlreadyQueued(localPending.join(', ')),
  ];
  return parts.isEmpty
      ? l10n.clientAgentsRequestBlockedFallback
      : l10n.clientAgentsRequestBlockedIntro(parts.join(' '));
}

String _localizeRequestQueued(
  ClientAgentsPresentationMessage message,
  AppLocalizations l10n,
) {
  return _requestQueuedMessage(
    l10n,
    queuedCount: _requiredInt(message, 'queuedCount'),
    ignoredCount: _requiredInt(message, 'ignoredCount'),
  );
}

String _requestQueuedMessage(
  AppLocalizations l10n, {
  required int queuedCount,
  required int ignoredCount,
}) {
  final baseMessage = queuedCount == 1
      ? l10n.clientAgentsRequestQueuedWatchingSingle
      : l10n.clientAgentsRequestQueuedWatchingPlural(queuedCount);
  if (ignoredCount == 0) {
    return baseMessage;
  }
  return '$baseMessage ${l10n.clientAgentsRequestQueuedIgnoredSuffix(ignoredCount)}';
}

String _relinkFeedbackMessage(AppLocalizations l10n, int relinkedCount) {
  return relinkedCount == 1
      ? l10n.clientAgentsRequestRelinkUpdatedSingle
      : l10n.clientAgentsRequestRelinkUpdatedPlural(relinkedCount);
}

String _withPendingCleanupNote({
  required String relinkMessage,
  required bool pendingCleanupOk,
  required AppLocalizations l10n,
}) {
  if (pendingCleanupOk) {
    return relinkMessage;
  }
  return '$relinkMessage ${l10n.clientAgentsRelinkPendingNotCleared}';
}

String _localizeRemoveBlocked(
  ClientAgentsPresentationMessage message,
  AppLocalizations l10n,
) {
  final notApproved = _requiredStrings(message, 'notApproved');
  final localPending = _requiredStrings(message, 'localPending');
  final parts = <String>[
    if (notApproved.isNotEmpty)
      l10n.clientAgentsRemoveBlockedNotApproved(notApproved.join(', ')),
    if (localPending.isNotEmpty)
      l10n.clientAgentsRemoveBlockedAlreadyQueued(localPending.join(', ')),
  ];
  return parts.isEmpty
      ? l10n.clientAgentsRemoveBlockedFallback
      : l10n.clientAgentsRemoveBlockedIntro(parts.join(' '));
}

String _removeQueuedMessage(
  AppLocalizations l10n, {
  required int queuedCount,
  required int ignoredCount,
}) {
  final baseMessage = queuedCount == 1
      ? l10n.clientAgentsRemoveQueuedSingle
      : l10n.clientAgentsRemoveQueuedPlural(queuedCount);
  if (ignoredCount == 0) {
    return baseMessage;
  }
  return '$baseMessage ${l10n.clientAgentsRemoveQueuedIgnoredSuffix(ignoredCount)}';
}

String _localizeSyncSuccess(
  ClientAgentsPresentationMessage message,
  AppLocalizations l10n,
) {
  final synced = _requiredInt(message, 'syncedCount');
  final failed = _requiredInt(message, 'failedCount');
  final attemptedPendingCount = _requiredInt(message, 'attemptedPendingCount');
  final autoTriggered = _requiredBool(message, 'autoTriggered');
  final watchingApproval = _requiredBool(message, 'watchingApproval');
  final alreadyApprovedCount = _requiredInt(message, 'alreadyApprovedCount');
  final debouncedCount = _requiredInt(message, 'debouncedCount');

  final String prefix;
  if (synced == 0 && attemptedPendingCount > 0) {
    prefix = l10n.clientAgentsSyncSuccessNoneCompleted;
  } else if (synced == 1) {
    prefix = l10n.clientAgentsSyncSuccessSingle;
  } else {
    prefix = l10n.clientAgentsSyncSuccessPlural(synced);
  }

  final suffix = autoTriggered
      ? l10n.clientAgentsSyncSuccessAutoSuffix
      : l10n.clientAgentsSyncSuccessManualSuffix;
  final polling = watchingApproval
      ? l10n.clientAgentsSyncSuccessPollingSuffix
      : '';
  var result = '$prefix$suffix$polling';

  if (alreadyApprovedCount > 0) {
    result += alreadyApprovedCount == 1
        ? l10n.clientAgentsSyncSuccessAlreadyApprovedSingle
        : l10n.clientAgentsSyncSuccessAlreadyApprovedPlural(
            alreadyApprovedCount,
          );
  }
  if (debouncedCount > 0) {
    result += debouncedCount == 1
        ? l10n.clientAgentsSyncSuccessDebouncedSingle
        : l10n.clientAgentsSyncSuccessDebouncedPlural(debouncedCount);
  }
  if (failed > 0) {
    result += l10n.clientAgentsSyncSuccessSomeFailedSuffix(failed);
  }

  return result;
}

String _localizeLocalTokenServerFlushFailed(
  ClientAgentsPresentationMessage message,
  AppLocalizations l10n,
) {
  final failedCount = _requiredInt(message, 'failedCount');
  if (failedCount == 1) {
    return l10n.clientAgentsLocalTokenServerFlushFailedSingle;
  }
  return l10n.clientAgentsLocalTokenServerFlushFailedPlural(failedCount);
}

String _localizeApprovalPollingProgress(
  ClientAgentsPresentationMessage message,
  AppLocalizations l10n,
) {
  final approvedCount = _requiredInt(message, 'approvedCount');
  final deniedCount = _requiredInt(message, 'deniedCount');
  final timedOutCount = _requiredInt(message, 'timedOutCount');
  final remainingCount = _requiredInt(message, 'remainingCount');
  final myAgentsTab = l10n.clientAgentsTabMyAgents;
  final parts = <String>[
    if (approvedCount > 0)
      approvedCount == 1
          ? l10n.clientAgentsPollApprovedSingle(myAgentsTab)
          : l10n.clientAgentsPollApprovedPlural(approvedCount, myAgentsTab),
    if (deniedCount > 0)
      deniedCount == 1
          ? l10n.clientAgentsPollDeniedSingle
          : l10n.clientAgentsPollDeniedPlural(deniedCount),
    if (timedOutCount > 0)
      timedOutCount == 1
          ? l10n.clientAgentsPollTimeoutSingle
          : l10n.clientAgentsPollTimeoutPlural(timedOutCount),
    if (remainingCount > 0)
      remainingCount == 1
          ? l10n.clientAgentsPollRemainingSingle
          : l10n.clientAgentsPollRemainingPlural(remainingCount),
  ];
  return parts.join(' ');
}

int _requiredInt(ClientAgentsPresentationMessage message, String key) {
  return (message.payload[key] as num?)?.toInt() ?? 0;
}

bool _requiredBool(ClientAgentsPresentationMessage message, String key) {
  return message.payload[key] as bool? ?? false;
}

List<String> _requiredStrings(
  ClientAgentsPresentationMessage message,
  String key,
) {
  final value = message.payload[key];
  if (value is List<String>) {
    return value;
  }
  if (value is List<Object?>) {
    return value.map((item) => item?.toString() ?? '').toList(growable: false);
  }
  return const <String>[];
}
