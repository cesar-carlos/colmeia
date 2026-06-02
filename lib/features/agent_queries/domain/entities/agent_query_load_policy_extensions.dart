import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';

extension AgentQueryLoadPolicyTransportX on AgentQueryLoadPolicy {
  bool get bypassTransportCache => this != AgentQueryLoadPolicy.defaultLoad;
}
