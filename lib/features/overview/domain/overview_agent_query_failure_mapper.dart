import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';

/// Maps merge-all participants with failures into detail rows for the UI.
List<OverviewAgentQueryFailureDetail> overviewPartialFailuresFromParticipants<
  Row
>(Iterable<AgentQueryExecutionParticipant<Row>> participants) {
  final out = <OverviewAgentQueryFailureDetail>[];
  for (final participant in participants) {
    final failure = participant.failure;
    if (failure == null) {
      continue;
    }
    out.add(
      OverviewAgentQueryFailureDetail(
        agentId: participant.agentId,
        displayName: participant.displayName,
        source: OverviewAgentQueryFailureSource.paymentResumo,
        userMessage: failure.displayMessage,
        technicalSummary: overviewAgentQueryFailureTechnicalSummary(failure),
      ),
    );
  }
  return out;
}
