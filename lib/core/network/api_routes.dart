abstract final class ApiRoutes {
  static const String dashboardsOverview = '/dashboards/overview';

  /// Hub operator route: requires a **user** principal. Client JWTs must not
  /// call this; use `/client/me/agents` payload (e.g. `isHubConnected`) instead.
  static const String onlineAgents = '/agents';
}

/// Hub bridge: `POST /api/v1/agents/commands` (base URL already includes `/api/v1`).
abstract final class AgentCommandsApiRoutes {
  static const String commands = '/agents/commands';
}

abstract final class AgentCatalogApiRoutes {
  static const String catalog = '/agents/catalog';

  static String catalogByAgentId(String agentId) => '$catalog/$agentId';

  static String profileByAgentId(String agentId) => '/agents/$agentId/profile';
}

abstract final class ClientAgentApiRoutes {
  static const String approvedAgents = '/client/me/agents';
  static const String accessRequests = '/client/me/agent-access-requests';
  static const String accessStatusByToken = '/client-access/status';

  static String approvedAgentById(String agentId) => '$approvedAgents/$agentId';

  static String retryAccessRequestById(String requestId) =>
      '$accessRequests/$requestId/retry';

  /// Per-(client, agent) bearer token used by the SQL bridge as
  /// `params.client_token`. Returned only by the dedicated GET; list/detail
  /// endpoints expose `hasClientToken: boolean` instead.
  static String clientTokenForAgent(String agentId) =>
      '${approvedAgentById(agentId)}/client-token';
}

abstract final class UserAgentApiRoutes {
  static const String managedAgents = '/me/agents';

  static String managedAgentClients(String agentId) =>
      '$managedAgents/$agentId/clients';

  static String managedAgentClientById({
    required String agentId,
    required String clientId,
  }) => '${managedAgentClients(agentId)}/$clientId';
}

abstract final class OwnerClientAccessApiRoutes {
  static const String accessRequests = '/me/client-access-requests';

  static String approveRequestById(String requestId) =>
      '$accessRequests/$requestId/approve';

  static String rejectRequestById(String requestId) =>
      '$accessRequests/$requestId/reject';
}

abstract final class ClientAuthApiRoutes {
  static const String register = '/client-auth/register';
  static const String registrationStatus = '/client-auth/registration/status';
  static const String login = '/client-auth/login';
  static const String refresh = '/client-auth/refresh';
  static const String logout = '/client-auth/logout';
  static const String me = '/client-auth/me';
  static const String password = '/client-auth/password';
  static const String thumbnail = '/client-auth/thumbnail';
  static const String passwordRecoveryRequest =
      '/client-auth/password-recovery/request';
  static const String passwordRecoveryStatus =
      '/client-auth/password-recovery/status';
  static const String passwordRecoveryReset =
      '/client-auth/password-recovery/reset';

  static const Set<String> unauthenticated = <String>{
    register,
    registrationStatus,
    login,
    refresh,
    logout,
    passwordRecoveryRequest,
    passwordRecoveryStatus,
    passwordRecoveryReset,
  };
}
