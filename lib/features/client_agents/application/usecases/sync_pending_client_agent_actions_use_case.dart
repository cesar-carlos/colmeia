import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class SyncPendingClientAgentActionsUseCase {
  SyncPendingClientAgentActionsUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<SyncPendingAgentActionsResult>> call({
    required String userId,
  }) {
    return _repository.syncPendingActions(userId: userId);
  }
}
