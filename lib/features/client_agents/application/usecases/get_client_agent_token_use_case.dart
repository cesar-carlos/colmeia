import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_repository.dart';

/// Reads the per-(client, agent) bearer token currently stored on the server.
///
/// Implementations may also keep a local cache so screens stay usable when the
/// server is briefly unreachable. Returns `Success(ClientAgentTokenSnapshot
/// .empty())` when no token is configured for the pair.
class GetClientAgentTokenUseCase {
  GetClientAgentTokenUseCase(this._repository);

  final AgentClientTokenRepository _repository;

  Future<AppResult<ClientAgentTokenSnapshot>> call({
    required String userId,
    required String agentId,
  }) {
    return _repository.getToken(userId: userId, agentId: agentId);
  }
}
