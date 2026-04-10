import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';

class AgentQueryTargetResolution {
  const AgentQueryTargetResolution({
    required this.consideredApprovedTargets,
    required this.missingClientTokenTargets,
    required this.consideredApprovedAgentCount,
    this.selectedAgentIds,
  });

  final List<AgentQueryTarget> consideredApprovedTargets;
  final List<AgentQueryTarget> missingClientTokenTargets;
  final int consideredApprovedAgentCount;
  final Set<String>? selectedAgentIds;

  bool get hasTargets => consideredApprovedTargets.isNotEmpty;
}
