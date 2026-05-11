import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';

class LoadAvailableAgentsForSales {
  LoadAvailableAgentsForSales(this._repository, this._clientTokenReader);

  static const int _pageSize = 100;

  final ClientAgentsRepository _repository;
  final AgentClientTokenReader _clientTokenReader;

  Future<List<OverviewAgentOption>> call(String userId) async {
    final agents = await _loadAllApprovedAgents(userId);
    if (agents == null) {
      return <OverviewAgentOption>[];
    }

    final agentIds = agents.map((agent) => agent.agentId);
    final tokensByAgent = await _clientTokenReader.readMany(
      userId: userId,
      agentIds: agentIds,
    );
    final tokenBackedAgentIds = tokensByAgent.keys.toSet();
    return agents
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

  Future<List<ClientAgent>?> _loadAllApprovedAgents(String userId) async {
    final agents = <ClientAgent>[];
    var page = 1;

    while (true) {
      final result = await _repository.loadApprovedAgents(
        userId: userId,
        query: PaginatedQuery(page: page, pageSize: _pageSize),
        includeOnlineStatus: false,
      );
      final paginated = result.fold((success) => success, (failure) => null);
      if (paginated == null) {
        return null;
      }

      agents.addAll(paginated.items);
      if (_isLastPage(paginated, loadedCount: agents.length)) {
        return agents;
      }

      page += 1;
    }
  }

  bool _isLastPage(
    PaginatedResult<ClientAgent> page, {
    required int loadedCount,
  }) {
    if (page.items.isEmpty) {
      return true;
    }
    if (loadedCount >= page.total) {
      return true;
    }
    return false;
  }
}
