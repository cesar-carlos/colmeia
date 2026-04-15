import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

/// Detail from `GET …/client/me/agents/{id}` only (no `/agents/catalog/...`).
class LoadClientAgentDetailUseCase {
  LoadClientAgentDetailUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<ClientAgent>> call({
    required String userId,
    required String agentId,
  }) {
    return _repository.loadApprovedAgentById(
      userId: userId,
      agentId: agentId,
    );
  }
}
