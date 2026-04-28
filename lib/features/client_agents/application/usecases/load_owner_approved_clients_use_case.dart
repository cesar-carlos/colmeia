import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadOwnerApprovedClientsUseCase {
  LoadOwnerApprovedClientsUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<List<OwnerApprovedClient>>> call({
    required String userId,
    required String agentId,
  }) {
    return _repository.loadOwnerApprovedClients(
      userId: userId,
      agentId: agentId,
    );
  }
}
