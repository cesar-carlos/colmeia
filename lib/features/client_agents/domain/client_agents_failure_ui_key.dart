/// Context field name and values for mapping client agent failures to l10n in
/// presentation.
abstract final class ClientAgentsFailureUiKey {
  static const String field = 'clientAgentsFailureUiKey';

  static const String loadCatalog = 'loadCatalog';
  static const String loadCatalogAgentById = 'loadCatalogAgentById';
  static const String loadApprovedAgents = 'loadApprovedAgents';
  static const String loadAgentDetail = 'loadAgentDetail';
  static const String probeApprovedAgentLink = 'probeApprovedAgentLink';
  static const String loadAccessRequests = 'loadAccessRequests';
  static const String loadClientAccessStatus = 'loadClientAccessStatus';
  static const String readPendingActions = 'readPendingActions';
  static const String queueRequestAccess = 'queueRequestAccess';
  static const String queueRemoveAccess = 'queueRemoveAccess';
  static const String syncPendingAction = 'syncPendingAction';
  static const String syncPendingActions = 'syncPendingActions';

  static const String getClientAgentToken = 'getClientAgentToken';
  static const String saveClientAgentToken = 'saveClientAgentToken';
  static const String removeClientAgentToken = 'removeClientAgentToken';
}
