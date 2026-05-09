import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';

class AgentQueryExecutionReport<Row> {
  const AgentQueryExecutionReport({
    required this.queryKey,
    required this.strategy,
    required this.consideredApprovedAgentCount,
    required this.plannedTargets,
    required this.missingClientTokenTargets,
    required this.participants,
    required this.totalElapsedMs,
    this.winnerAgentId,
    this.skippedDueToHubPresenceTargets = const <AgentQueryTarget>[],
  });

  final AgentQueryKey queryKey;
  final AgentQueryExecutionStrategy strategy;
  final int consideredApprovedAgentCount;
  final List<AgentQueryTarget> plannedTargets;
  final List<AgentQueryTarget> missingClientTokenTargets;
  final List<AgentQueryExecutionParticipant<Row>> participants;
  final String? winnerAgentId;
  final int totalElapsedMs;

  /// Agents that DO carry a stored client_token but were excluded
  /// at planning time because the hub-presence policy
  /// (`is_hub_connected` from `/client/me/agents`) marked them as
  /// offline. The agent operator must reconnect them to the hub —
  /// fixing the missing-token agents would NOT bring these back.
  /// Kept separate from [missingClientTokenTargets] so the
  /// presentation layer can render a dedicated "agentes offline"
  /// banner with actionable copy.
  final List<AgentQueryTarget> skippedDueToHubPresenceTargets;

  List<Row> get mergedRows {
    return participants
        .where((participant) => participant.isSuccess)
        .expand((participant) => participant.rows)
        .toList(growable: false);
  }

  Map<String, List<Row>> get rowsByAgentId {
    final rows = <String, List<Row>>{
      for (final target in plannedTargets) target.agentId: <Row>[],
      for (final target in missingClientTokenTargets) target.agentId: <Row>[],
    };
    for (final participant in participants) {
      rows[participant.agentId] = List<Row>.from(
        participant.rows,
        growable: false,
      );
    }
    return rows;
  }

  List<String> get failedAgentIds {
    return participants
        .where((participant) => participant.failure != null)
        .map((participant) => participant.agentId)
        .toList(growable: false);
  }

  List<String> get failedAgentNames {
    return participants
        .where((participant) => participant.failure != null)
        .map((participant) => participant.displayName)
        .toList(growable: false);
  }

  List<String> get missingClientTokenAgentIds {
    return missingClientTokenTargets
        .map((target) => target.agentId)
        .toList(growable: false);
  }

  List<String> get missingClientTokenAgentNames {
    return missingClientTokenTargets
        .map((target) => target.displayName)
        .toList(growable: false);
  }

  List<String> get skippedDueToHubPresenceAgentIds {
    return skippedDueToHubPresenceTargets
        .map((target) => target.agentId)
        .toList(growable: false);
  }

  List<String> get skippedDueToHubPresenceAgentNames {
    return skippedDueToHubPresenceTargets
        .map((target) => target.displayName)
        .toList(growable: false);
  }

  /// True only when **no** agent could run the query (`plannedTargets` empty)
  /// while some selected agents still need a local `client_token`.
  ///
  /// If at least one agent ran successfully (even returning zero SQL rows),
  /// this is **false** so callers do not conflate "no sales in period" with
  /// "cannot execute until tokens are provisioned".
  bool get requiresClientTokenSetup => skippedOnlyDueToMissingClientTokens;

  bool get skippedOnlyDueToMissingClientTokens =>
      plannedTargets.isEmpty && missingClientTokenTargets.isNotEmpty;

  bool get hasPartialFailure =>
      participants.any((participant) => participant.isSuccess) &&
      participants.any((participant) => !participant.isSuccess);

  bool get hasRows => mergedRows.isNotEmpty;
}
