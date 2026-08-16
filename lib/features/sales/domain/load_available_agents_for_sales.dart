import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolution_cache.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

class LoadAvailableAgentsForSales {
  LoadAvailableAgentsForSales(
    this._repository,
    this._clientTokenReader,
  ) : _targetResolver = null,
      _resolutionCache = null;

  LoadAvailableAgentsForSales.fromTargetResolver(
    this._targetResolver, {
    this._resolutionCache,
  }) : _repository = null,
       _clientTokenReader = null;

  static const int _pageSize = 100;

  final ClientAgentsRepository? _repository;
  final AgentClientTokenReader? _clientTokenReader;
  final AgentQueryTargetResolver? _targetResolver;
  final AgentQueryTargetResolutionCache? _resolutionCache;

  Future<List<DashboardAgentOption>> call(String userId) async {
    final resolver = _targetResolver;
    if (resolver != null) {
      return _loadFromTargetResolver(resolver, userId: userId);
    }

    final agents = await _loadAllApprovedAgents(userId);
    if (agents == null) {
      return <DashboardAgentOption>[];
    }

    final agentIds = agents.map((agent) => agent.agentId);
    final tokensByAgent = await _clientTokenReader!.readMany(
      userId: userId,
      agentIds: agentIds,
    );
    final tokenBackedAgentIds = tokensByAgent.keys.toSet();
    return agents
        .map(
          (agent) => DashboardAgentOption(
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

  Future<List<DashboardAgentOption>> _loadFromTargetResolver(
    AgentQueryTargetResolver resolver, {
    required String userId,
  }) async {
    final resolution = await _resolveForSales(
      userId: userId,
      resolver: resolver,
    );
    if (resolution == null) {
      return <DashboardAgentOption>[];
    }

    return resolution.consideredApprovedTargets
        .map(
          (target) => DashboardAgentOption(
            agentId: target.agentId,
            name: target.displayName,
            connectionStatus: target.connectionStatus,
            missingLocalClientToken: !target.hasClientToken,
          ),
        )
        .toList(growable: false);
  }

  Future<AgentQueryTargetResolution?> _resolveForSales({
    required String userId,
    required AgentQueryTargetResolver resolver,
  }) async {
    final cached = _resolutionCache?.read(userId: userId);
    if (cached != null) {
      return cached;
    }
    final result = await resolver.resolve(userId: userId);
    return result.getOrNull();
  }

  Future<List<ClientAgent>?> _loadAllApprovedAgents(String userId) async {
    final agents = <ClientAgent>[];
    var page = 1;

    while (true) {
      final result = await _repository!.loadApprovedAgents(
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
