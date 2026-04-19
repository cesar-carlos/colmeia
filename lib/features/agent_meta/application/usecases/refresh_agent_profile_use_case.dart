import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';

/// Forces a fresh `agent.getProfile` call against the agent (via the hub
/// bridge). Useful to confirm the catalog snapshot when the user suspects
/// it's stale, without waiting for the realtime
/// `client:agent.profile.updated` push.
class RefreshAgentProfileUseCase {
  RefreshAgentProfileUseCase(this._repository);

  final AgentMetaRepository _repository;

  Future<AppResult<AgentProfileSnapshot>> call({
    required String agentId,
    String? clientToken,
  }) {
    return _repository.getAgentProfile(
      agentId: agentId,
      clientToken: clientToken,
    );
  }
}
