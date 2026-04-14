import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'skippedOnlyDueToMissingClientTokens is true when nothing is runnable',
    () {
      const report = AgentQueryExecutionReport<int>(
        queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[
          AgentQueryTarget(
            agentId: 'x',
            displayName: 'X',
            connectionStatus: AgentConnectionStatus.unknown,
          ),
        ],
        participants: <AgentQueryExecutionParticipant<int>>[],
        totalElapsedMs: 0,
      );
      check(report.skippedOnlyDueToMissingClientTokens).isTrue();
      check(report.requiresClientTokenSetup).isTrue();
    },
  );
}
