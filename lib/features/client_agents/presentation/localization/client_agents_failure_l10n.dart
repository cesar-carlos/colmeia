import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/l10n/app_localizations.dart';

String clientAgentsFailureUserMessage(
  AppFailure failure,
  AppLocalizations l10n,
) {
  if (failure is ValidationFailure) {
    final code = failure.context[ApiErrorContext.apiErrorCode] as String?;
    if (code == ApiConflictErrorCode.agentDocumentConflict) {
      return l10n.clientAgentsErrorAgentDocumentConflict;
    }
  }
  final key = failure.context[ClientAgentsFailureUiKey.field] as String?;
  if (key == null) {
    return failure.displayMessage;
  }
  return switch (key) {
    ClientAgentsFailureUiKey.loadCatalog => l10n.clientAgentsErrorLoadCatalog,
    ClientAgentsFailureUiKey.loadCatalogAgentById =>
      l10n.clientAgentsErrorLoadCatalogAgent,
    ClientAgentsFailureUiKey.loadApprovedAgents =>
      l10n.clientAgentsErrorLoadApproved,
    ClientAgentsFailureUiKey.loadAgentDetail =>
      l10n.clientAgentsErrorLoadAgentDetail,
    ClientAgentsFailureUiKey.probeApprovedAgentLink =>
      l10n.clientAgentsErrorProbeApproved,
    ClientAgentsFailureUiKey.loadAccessRequests =>
      l10n.clientAgentsErrorLoadAccessRequests,
    ClientAgentsFailureUiKey.loadClientAccessStatus =>
      l10n.clientAgentsErrorLoadClientAccessStatus,
    ClientAgentsFailureUiKey.readPendingActions =>
      l10n.clientAgentsErrorReadPending,
    ClientAgentsFailureUiKey.queueRequestAccess =>
      l10n.clientAgentsErrorQueueRequest,
    ClientAgentsFailureUiKey.queueRemoveAccess =>
      l10n.clientAgentsErrorQueueRemove,
    ClientAgentsFailureUiKey.syncPendingAction =>
      l10n.clientAgentsErrorSyncAction,
    ClientAgentsFailureUiKey.syncPendingActions =>
      l10n.clientAgentsErrorSyncPending,
    _ => failure.displayMessage,
  };
}
