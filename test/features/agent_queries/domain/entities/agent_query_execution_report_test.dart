import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
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

  test(
    'requiresClientTokenSetup is false when agents ran but SQL returned no rows',
    () {
      const report = AgentQueryExecutionReport<int>(
        queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[
          AgentQueryTarget(
            agentId: 'a',
            displayName: 'A',
            connectionStatus: AgentConnectionStatus.online,
            clientToken: 'tok',
          ),
        ],
        missingClientTokenTargets: <AgentQueryTarget>[
          AgentQueryTarget(
            agentId: 'b',
            displayName: 'B',
            connectionStatus: AgentConnectionStatus.unknown,
          ),
        ],
        participants: <AgentQueryExecutionParticipant<int>>[
          AgentQueryExecutionParticipant<int>(
            agentId: 'a',
            displayName: 'A',
            rows: <int>[],
            elapsedMs: 1,
          ),
        ],
        totalElapsedMs: 1,
      );
      check(report.mergedRows).isEmpty();
      check(report.skippedOnlyDueToMissingClientTokens).isFalse();
      check(report.requiresClientTokenSetup).isFalse();
    },
  );

  test(
    'hasPartialFailure is true when one target succeeds with zero rows and '
    'another fails',
    () {
      const report = AgentQueryExecutionReport<int>(
        queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 2,
        plannedTargets: <AgentQueryTarget>[
          AgentQueryTarget(
            agentId: 'a',
            displayName: 'A',
            connectionStatus: AgentConnectionStatus.online,
            clientToken: 'tok-a',
          ),
          AgentQueryTarget(
            agentId: 'b',
            displayName: 'B',
            connectionStatus: AgentConnectionStatus.online,
            clientToken: 'tok-b',
          ),
        ],
        missingClientTokenTargets: <AgentQueryTarget>[],
        participants: <AgentQueryExecutionParticipant<int>>[
          AgentQueryExecutionParticipant<int>(
            agentId: 'a',
            displayName: 'A',
            rows: <int>[],
            elapsedMs: 1,
          ),
          AgentQueryExecutionParticipant<int>(
            agentId: 'b',
            displayName: 'B',
            rows: <int>[],
            failure: UnknownFailure(message: 'failed'),
            elapsedMs: 1,
          ),
        ],
        totalElapsedMs: 1,
      );

      check(report.hasRows).isFalse();
      check(report.hasPartialFailure).isTrue();
    },
  );
}
