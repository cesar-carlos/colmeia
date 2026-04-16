import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class DiscardQueuedClientAgentRequestAccessUseCase {
  DiscardQueuedClientAgentRequestAccessUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<Unit>> call({
    required String userId,
    required Set<String> agentIds,
  }) {
    return _repository.discardQueuedRequestAccessForAgents(
      userId: userId,
      agentIds: agentIds,
    );
  }
}
