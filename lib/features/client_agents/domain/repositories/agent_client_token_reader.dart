/// Stable token reader abstraction so `agent_queries` does not depend on a
/// concrete storage or transport (secure storage, REST, in-memory).
///
/// The concrete implementation may resolve tokens from local cache and/or
/// the server-side endpoint `GET /client/me/agents/{agentId}/client-token`.
/// Callers must treat missing entries as "no token available for this agent"
/// (the SQL bridge will reject the request without a token).
// ignore: one_member_abstracts
abstract interface class AgentClientTokenReader {
  /// Returns a map agentId → token, including only agents that currently have
  /// a non-empty token resolvable by the implementation. Missing entries are
  /// not errors — callers decide whether to skip the agent or surface a hint.
  Future<Map<String, String>> readMany({
    required String userId,
    required Iterable<String> agentIds,
  });
}
