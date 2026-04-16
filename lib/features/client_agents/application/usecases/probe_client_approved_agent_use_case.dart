import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class ProbeClientApprovedAgentUseCase {
  ProbeClientApprovedAgentUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<ClientApprovedAgentProbeOutcome>> call({
    required String userId,
    required String agentId,
  }) {
    return _repository.probeApprovedAgentLink(
      userId: userId,
      agentId: agentId,
    );
  }
}
