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
  });

  final AgentQueryKey queryKey;
  final AgentQueryExecutionStrategy strategy;
  final int consideredApprovedAgentCount;
  final List<AgentQueryTarget> plannedTargets;
  final List<AgentQueryTarget> missingClientTokenTargets;
  final List<AgentQueryExecutionParticipant<Row>> participants;
  final String? winnerAgentId;
  final int totalElapsedMs;

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

  bool get requiresClientTokenSetup =>
      mergedRows.isEmpty && missingClientTokenTargets.isNotEmpty;

  bool get skippedOnlyDueToMissingClientTokens =>
      plannedTargets.isEmpty && missingClientTokenTargets.isNotEmpty;

  bool get hasPartialFailure =>
      mergedRows.isNotEmpty &&
      participants.any((participant) => !participant.isSuccess);

  bool get hasRows => mergedRows.isNotEmpty;
}
