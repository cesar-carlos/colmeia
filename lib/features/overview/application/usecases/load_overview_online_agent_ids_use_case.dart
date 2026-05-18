import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

class LoadOverviewOnlineAgentIdsUseCase {
  LoadOverviewOnlineAgentIdsUseCase(this._clientAgentsRepository);

  final ClientAgentsRepository _clientAgentsRepository;

  Future<Set<String>> call({required String userId}) async {
    return await _clientAgentsRepository.loadOnlineAgentIds(userId: userId) ??
        <String>{};
  }
}
