import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';

/// Resolves approved agents, client tokens and hub presence into SQL targets.
// ignore: one_member_abstracts
abstract interface class AgentQueryTargetResolver {
  Future<AppResult<AgentQueryTargetResolution>> resolve({
    required String userId,
    Set<String>? selectedAgentIds,
  });
}
