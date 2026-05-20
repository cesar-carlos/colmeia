import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:result_dart/result_dart.dart';

class PersistClientAgentProfileSnapshotUseCase {
  PersistClientAgentProfileSnapshotUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<Unit>> call({
    required String userId,
    required String agentId,
    required AgentProfileSnapshot snapshot,
  }) {
    return _repository.applyApprovedAgentProfileSnapshotLocally(
      userId: userId,
      agentId: agentId,
      snapshot: snapshot,
    );
  }
}
