import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_policy.dart';
import 'package:colmeia/features/client_agents/domain/client_agent_display_name.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agents_list_page_size.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/client_agents/domain/services/agent_connection_status_resolver.dart';
import 'package:result_dart/result_dart.dart';

class AgentQueryTargetResolver {
  AgentQueryTargetResolver({
    required ClientAgentsRepository clientAgentsRepository,
    required AgentClientTokenReader clientTokenReader,
    AgentSqlExecutionEligibilityPolicy policy =
        const AgentSqlExecutionEligibilityPolicy(),
  }) : _clientAgentsRepository = clientAgentsRepository,
       _clientTokenReader = clientTokenReader,
       _presencePolicy = policy;

  final ClientAgentsRepository _clientAgentsRepository;
  final AgentClientTokenReader _clientTokenReader;
  final AgentSqlExecutionEligibilityPolicy _presencePolicy;

  static const int _maxApprovedAgentsPaginationPages = 400;
  static const String _paginationSignatureSeparator = '\u001f';

  Future<AppResult<AgentQueryTargetResolution>> resolve({
    required String userId,
    Set<String>? selectedAgentIds,
  }) async {
    final normalizedSelectedIds = _normalizeSelectedIds(selectedAgentIds);
    if (normalizedSelectedIds != null && normalizedSelectedIds.isEmpty) {
      return const Success<AgentQueryTargetResolution, AppFailure>(
        AgentQueryTargetResolution(
          consideredApprovedTargets: <AgentQueryTarget>[],
          missingClientTokenTargets: <AgentQueryTarget>[],
          consideredApprovedAgentCount: 0,
          selectedAgentIds: <String>{},
          sqlEligibleConsideredTargetCount: 0,
        ),
      );
    }
    final approvedAgentsResult = await _loadAllApprovedAgents(userId: userId);
    final approvedAgents = approvedAgentsResult.getOrNull();
    if (approvedAgents == null) {
      return Failure<AgentQueryTargetResolution, AppFailure>(
        approvedAgentsResult.exceptionOrNull()!,
      );
    }

    if (approvedAgents.isEmpty) {
      return Failure<AgentQueryTargetResolution, AppFailure>(
        ValidationFailure(
          message: 'No approved agents available for agent query',
          context: <String, Object?>{
            'operation': 'resolveAgentQueryTargets',
            'userId': userId,
            'reason': 'no_approved_agents',
          },
        ),
      );
    }

    final filteredAgents = normalizedSelectedIds == null
        ? approvedAgents
        : approvedAgents
              .where((agent) => normalizedSelectedIds.contains(agent.agentId))
              .toList(growable: false);

    if (filteredAgents.isEmpty) {
      return Success<AgentQueryTargetResolution, AppFailure>(
        AgentQueryTargetResolution(
          consideredApprovedTargets: const <AgentQueryTarget>[],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: 0,
          selectedAgentIds: normalizedSelectedIds,
          sqlEligibleConsideredTargetCount: 0,
        ),
      );
    }

    final sortedAgents = filteredAgents.toList(growable: false)
      ..sort((left, right) => left.agentId.compareTo(right.agentId));
    final parallel = await Future.wait(<Future<Object?>>[
      _clientTokenReader.readMany(
        userId: userId,
        agentIds: sortedAgents.map((agent) => agent.agentId),
      ),
      _clientAgentsRepository.loadOnlineAgentIds(userId: userId),
    ]);
    final tokensByAgentId = parallel[0]! as Map<String, String>;
    final onlineIds = parallel[1] as Set<String>?;

    final consideredTargets = sortedAgents.map((agent) {
      final hubSignal = _hubSignalFromFastApprovedPresenceRow(
        agent.connectionStatus,
      );
      final presenceStatus = resolveAgentConnectionStatus(
        agentId: agent.agentId,
        isHubConnected: hubSignal,
        onlineAgentIds: onlineIds,
      );
      return AgentQueryTarget(
        agentId: agent.agentId,
        displayName: resolveClientAgentDisplayName(agent, agent.agentId),
        connectionStatus: presenceStatus,
        clientToken: tokensByAgentId[agent.agentId],
        hubConnectedFromApprovedCatalogRow: hubSignal,
      );
    }).toList(growable: false);
    final missingClientTokenTargets = consideredTargets
        .where((target) => !target.hasClientToken)
        .toList(growable: false);

    final skippedDueToHubPresenceTargets = onlineIds == null
        ? const <AgentQueryTarget>[]
        : consideredTargets
              .where(
                (target) =>
                    target.hasClientToken &&
                    !_presencePolicy.sqlAllowedForStatus(
                      target.connectionStatus,
                    ),
              )
              .toList(growable: false);

    if (skippedDueToHubPresenceTargets.isNotEmpty) {
      AppLogger.info(
        'Agent query targets skipped due to hub presence rules',
        context: <String, Object?>{
          'operation': 'resolveAgentQueryTargets',
          'userId': userId,
          'skippedAgentIds': skippedDueToHubPresenceTargets
              .map((t) => t.agentId)
              .join(', '),
          'skippedCount': skippedDueToHubPresenceTargets.length,
        },
      );
    }

    final sqlEligibleConsideredTargetCount = consideredTargets
        .where(
          (target) =>
              target.hasClientToken &&
              (onlineIds == null ||
                  _presencePolicy.sqlAllowedForStatus(
                    target.connectionStatus,
                  )),
        )
        .length;

    return Success<AgentQueryTargetResolution, AppFailure>(
      AgentQueryTargetResolution(
        consideredApprovedTargets: consideredTargets,
        missingClientTokenTargets: missingClientTokenTargets,
        consideredApprovedAgentCount: consideredTargets.length,
        selectedAgentIds: normalizedSelectedIds,
        hubPresenceOnlineAgentIdsSnapshot: onlineIds,
        skippedDueToHubPresenceTargets: skippedDueToHubPresenceTargets,
        sqlEligibleConsideredTargetCount: sqlEligibleConsideredTargetCount,
      ),
    );
  }

  /// Approved agents are loaded with `includeOnlineStatus: false` for speed;
  /// hub rows are then merged with `loadOnlineAgentIds` before building targets.
  Future<AppResult<List<ClientAgent>>> _loadAllApprovedAgents({
    required String userId,
  }) async {
    final agents = <ClientAgent>[];
    var page = 1;
    String? previousPageSignature;
    while (true) {
      if (page > _maxApprovedAgentsPaginationPages) {
        AppLogger.warning(
          'Approved agents pagination stopped at safety page limit',
          context: <String, Object?>{
            'operation': 'resolveAgentQueryTargets',
            'userId': userId,
            'maxPages': _maxApprovedAgentsPaginationPages,
            'loadedCount': agents.length,
          },
        );
        break;
      }

      final query = PaginatedQuery(
        page: page,
        pageSize: kClientAgentsListPageSize,
      );
      final result = await _clientAgentsRepository.loadApprovedAgents(
        userId: userId,
        query: query,
        includeOnlineStatus: false,
      );
      final batch = result.getOrNull();
      if (batch == null) {
        return Failure<List<ClientAgent>, AppFailure>(
          result.exceptionOrNull()!,
        );
      }
      if (batch.items.isEmpty) {
        break;
      }

      final pageItemsSignature = batch.items
          .map((agent) => agent.agentId)
          .join(_paginationSignatureSeparator);
      final pageSignature =
          '${batch.page}$_paginationSignatureSeparator$pageItemsSignature';
      if (pageSignature == previousPageSignature) {
        AppLogger.warning(
          'Approved agents pagination: duplicate page payload; stopping',
          context: <String, Object?>{
            'operation': 'resolveAgentQueryTargets',
            'userId': userId,
            'page': batch.page,
          },
        );
        break;
      }
      previousPageSignature = pageSignature;

      agents.addAll(batch.items);

      final loadedAllKnownTotal =
          batch.total > 0 && agents.length >= batch.total;
      final lastPage = batch.items.length < query.pageSize;
      if (loadedAllKnownTotal || lastPage) {
        break;
      }
      page++;
    }
    return Success<List<ClientAgent>, AppFailure>(agents);
  }

  Set<String>? _normalizeSelectedIds(Set<String>? selectedAgentIds) {
    if (selectedAgentIds == null) {
      return null;
    }
    final ids = selectedAgentIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    return ids;
  }
}

/// Infers the per-row hub flag from [ClientAgentsRepository.loadApprovedAgents]
/// when `includeOnlineStatus` is false (onlineIds null during that mapping).
///
/// **Contract coupling:** if `loadApprovedAgents` ever changes what
/// [ClientAgent.connectionStatus] means when `includeOnlineStatus` is false,
/// this mapping must be updated or replaced with an explicit DTO field.
bool? _hubSignalFromFastApprovedPresenceRow(AgentConnectionStatus status) {
  return switch (status) {
    AgentConnectionStatus.online => true,
    AgentConnectionStatus.offline => false,
    AgentConnectionStatus.unknown => null,
  };
}
