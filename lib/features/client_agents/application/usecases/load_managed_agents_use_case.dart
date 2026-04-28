import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadManagedAgentsUseCase {
  LoadManagedAgentsUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<List<ClientAgent>>> call({required String userId}) {
    return _repository.loadManagedAgents(userId: userId);
  }
}
