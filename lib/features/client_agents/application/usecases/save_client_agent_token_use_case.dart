import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_repository.dart';

/// Stores a bearer token on the server for `(userId, agentId)` and mirrors
/// it into the local cache.
///
/// Returns the normalized server snapshot (`token` is `null` when an empty
/// string was sent — the server treats that as "clear the token").
class SaveClientAgentTokenUseCase {
  SaveClientAgentTokenUseCase(this._repository);

  final AgentClientTokenRepository _repository;

  Future<AppResult<ClientAgentTokenSnapshot>> call({
    required String userId,
    required String agentId,
    required String clientToken,
  }) {
    return _repository.saveToken(
      userId: userId,
      agentId: agentId,
      clientToken: clientToken,
    );
  }
}
