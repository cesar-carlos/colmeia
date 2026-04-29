import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';

class LoadAvailableAgentsForSales {
  LoadAvailableAgentsForSales(this._repository);

  final ClientAgentsRepository _repository;

  Future<List<OverviewAgentOption>> call(String userId) async {
    final result = await _repository.loadApprovedAgents(
      userId: userId,
      query: const PaginatedQuery(pageSize: 100),
      includeOnlineStatus: false,
    );

    return result.fold(
      (paginated) {
        return paginated.items
            .map(
              (agent) => OverviewAgentOption(
                agentId: agent.agentId,
                name: agent.name,
                connectionStatus: agent.connectionStatus,
              ),
            )
            .toList();
      },
      (failure) => <OverviewAgentOption>[],
    );
  }
}
