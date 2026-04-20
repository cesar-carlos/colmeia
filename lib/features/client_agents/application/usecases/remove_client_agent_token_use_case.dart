import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_repository.dart';
import 'package:result_dart/result_dart.dart';

/// Clears the per-(client, agent) bearer token on the server and locally.
class RemoveClientAgentTokenUseCase {
  RemoveClientAgentTokenUseCase(this._repository);

  final AgentClientTokenRepository _repository;

  Future<AppResult<Unit>> call({
    required String userId,
    required String agentId,
  }) {
    return _repository.removeToken(userId: userId, agentId: agentId);
  }
}
