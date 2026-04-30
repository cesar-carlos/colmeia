import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';

class LoadAvailableAgentsForSales {
  LoadAvailableAgentsForSales(this._repository, this._clientTokenReader);

  final ClientAgentsRepository _repository;
  final AgentClientTokenReader _clientTokenReader;

  Future<List<OverviewAgentOption>> call(String userId) async {
    final result = await _repository.loadApprovedAgents(
      userId: userId,
      query: const PaginatedQuery(pageSize: 100),
      includeOnlineStatus: false,
    );
    final paginated = result.fold((success) => success, (failure) => null);
    if (paginated == null) {
      return <OverviewAgentOption>[];
    }

    final agentIds = paginated.items.map((agent) => agent.agentId);
    final tokensByAgent = await _clientTokenReader.readMany(
      userId: userId,
      agentIds: agentIds,
    );
    final tokenBackedAgentIds = tokensByAgent.keys.toSet();
    return paginated.items
        .map(
          (agent) => OverviewAgentOption(
            agentId: agent.agentId,
            name: agent.name,
            connectionStatus: agent.connectionStatus,
            missingLocalClientToken: !tokenBackedAgentIds.contains(
              agent.agentId,
            ),
          ),
        )
        .toList();
  }
}
