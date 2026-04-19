import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';

/// Reads the authorization policy resolved by the agent for the supplied
/// `clientToken`.
///
/// Returns `ClientTokenPolicySnapshot.unsupported()` when the agent does
/// not implement `client_token.getPolicy` (older profile / introspection
/// disabled), so the UI can hide the section without surfacing an error.
class LoadClientTokenPolicyUseCase {
  LoadClientTokenPolicyUseCase(this._repository);

  final AgentMetaRepository _repository;

  Future<AppResult<ClientTokenPolicySnapshot>> call({
    required String agentId,
    required String clientToken,
  }) {
    return _repository.getClientTokenPolicy(
      agentId: agentId,
      clientToken: clientToken,
    );
  }
}
