import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';

class ClientAgentTokenDraftStore {
  ClientAgentTokenDraftStore(this._localStore);

  final LocalAgentClientTokenStore _localStore;

  Future<String?> read({
    required String userId,
    required String agentId,
  }) {
    return _localStore.read(userId: userId, agentId: agentId);
  }

  Future<void> write({
    required String userId,
    required String agentId,
    required String clientToken,
  }) {
    return _localStore.write(
      userId: userId,
      agentId: agentId,
      clientToken: clientToken,
    );
  }

  Future<void> delete({
    required String userId,
    required String agentId,
  }) {
    return _localStore.delete(userId: userId, agentId: agentId);
  }
}
