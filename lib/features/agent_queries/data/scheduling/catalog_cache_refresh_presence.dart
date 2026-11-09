import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_approved_agents_repository.dart';
import 'package:colmeia/shared/domain/agent_connection_status.dart';

class CatalogCacheRefreshPresence implements CacheRefreshPresence {
  CatalogCacheRefreshPresence(this._agents);
  final ClientApprovedAgentsRepository _agents;
  @override
  Future<RefreshAgentAvailability> reconcile(String user, String agent) async {
    final result = await _agents.probeApprovedAgentLink(
      userId: user,
      agentId: agent,
    );
    final failure = result.exceptionOrNull();
    if (failure is AuthorizationFailure) return RefreshAgentAvailability.denied;
    if (failure is NetworkFailure) {
      throw NetworkFailure(
        message: failure.message,
        retryAfter: failure.retryAfter,
        cause: failure.cause,
        context: {...failure.context, 'refreshHubUnavailable': true},
      );
    }
    final probe = result.getOrThrow();
    if (!probe.isLinked) return RefreshAgentAvailability.denied;
    return switch (probe.agent!.connectionStatus) {
      AgentConnectionStatus.online => RefreshAgentAvailability.online,
      AgentConnectionStatus.offline => RefreshAgentAvailability.offline,
      _ => RefreshAgentAvailability.unknown,
    };
  }
}
