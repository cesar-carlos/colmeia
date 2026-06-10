import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_policy.dart';

AgentQueryLoadPolicy mapOverviewLoadPolicyToAgentQuery(
  OverviewLoadPolicy policy,
) {
  return switch (policy) {
    OverviewLoadPolicy.defaultLoad => AgentQueryLoadPolicy.defaultLoad,
    OverviewLoadPolicy.forceRefresh => AgentQueryLoadPolicy.forceRefresh,
  };
}
