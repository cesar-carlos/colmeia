import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadCatalogAgentByIdUseCase {
  LoadCatalogAgentByIdUseCase(this._repository);

  final ClientAgentsRepository _repository;

  Future<AppResult<ClientAgentCatalogItem>> call({
    required String userId,
    required String agentId,
  }) {
    return _repository.loadCatalogAgentById(userId: userId, agentId: agentId);
  }
}
