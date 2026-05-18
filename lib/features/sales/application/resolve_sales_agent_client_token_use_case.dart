import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';

class ResolveSalesAgentClientTokenUseCase {
  ResolveSalesAgentClientTokenUseCase(this._tokenReader);

  final AgentClientTokenReader _tokenReader;

  Future<String?> call({
    required String userId,
    required String agentId,
  }) async {
    final tokensByAgent = await _tokenReader.readMany(
      userId: userId,
      agentIds: <String>[agentId],
    );
    final resolved = tokensByAgent[agentId]?.trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }
    return resolved;
  }
}
