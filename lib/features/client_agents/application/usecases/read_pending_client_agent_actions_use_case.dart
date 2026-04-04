import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class ReadPendingClientAgentActionsUseCase {
  ReadPendingClientAgentActionsUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<List<PendingAgentAction>>> call({
    required String userId,
  }) {
    return _repository.readPendingActions(userId: userId);
  }
}
