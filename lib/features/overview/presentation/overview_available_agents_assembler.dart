import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';

/// Builds the filter dropdown options from overview rows and failure metadata.
abstract final class OverviewAvailableAgentsAssembler {
  static List<OverviewAgentOption> assemble({
    required Overview overview,
    required List<OverviewAgentOption> previousOptions,
    required Set<String>? onlineAgentIds,
  }) {
    final seen = <String, String>{};
    for (final r in overview.agentRankings) {
      seen[r.agentId] = r.displayName;
    }
    for (var i = 0; i < overview.agentIdsExcludedFromQueryFailure.length; i++) {
      final id = overview.agentIdsExcludedFromQueryFailure[i];
      final name = i < overview.agentNamesExcludedFromQueryFailure.length
          ? overview.agentNamesExcludedFromQueryFailure[i]
          : id;
      seen[id] = name;
    }
    for (var i = 0; i < overview.agentIdsMissingClientToken.length; i++) {
      final id = overview.agentIdsMissingClientToken[i];
      final name = i < overview.agentNamesMissingClientToken.length
          ? overview.agentNamesMissingClientToken[i]
          : id;
      seen[id] = name;
    }

    final merged = <String, String>{
      for (final opt in previousOptions) opt.agentId: opt.name,
      ...seen,
    };

    if (merged.isEmpty) {
      return const <OverviewAgentOption>[];
    }

    final missingTokenIds = overview.agentIdsMissingClientToken.toSet();

    return merged.entries
        .map(
          (e) => OverviewAgentOption(
            agentId: e.key,
            name: e.value,
            connectionStatus: _connectionStatusFor(onlineAgentIds, e.key),
            missingLocalClientToken: missingTokenIds.contains(e.key),
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static AgentConnectionStatus _connectionStatusFor(
    Set<String>? onlineIds,
    String agentId,
  ) {
    if (onlineIds == null) {
      return AgentConnectionStatus.unknown;
    }
    return onlineIds.contains(agentId)
        ? AgentConnectionStatus.online
        : AgentConnectionStatus.offline;
  }
}
