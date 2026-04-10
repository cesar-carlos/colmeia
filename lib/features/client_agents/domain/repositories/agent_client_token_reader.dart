/// Single-method contract kept explicit so `agent_queries` can depend on a
/// stable token reader abstraction instead of concrete secure-storage code.
// ignore: one_member_abstracts
abstract interface class AgentClientTokenReader {
  Future<Map<String, String>> readMany({
    required String userId,
    required Iterable<String> agentIds,
  });
}
