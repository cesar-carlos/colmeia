import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class UpdateClientAgentProfileUseCase {
  UpdateClientAgentProfileUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<ClientAgent>> call({
    required String userId,
    required String agentId,
    required AgentProfileUpdateRequest request,
  }) {
    return _repository.updateCatalogAgentProfile(
      userId: userId,
      agentId: agentId,
      request: request,
    );
  }
}
