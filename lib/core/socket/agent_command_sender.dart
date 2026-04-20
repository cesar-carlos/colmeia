/// Minimal port the agent-queries datasource depends on for sending
/// `agents:command` payloads. Two implementations live in `core/socket/`:
///
/// - `DirectAgentCommandSender` — forwards every call straight to
///   `SocketCommandDispatcher` (used when batching is disabled).
/// - `AgentCommandBatchCoordinator` — aggregates concurrent calls into
///   a JSON-RPC batch (used when `SOCKET_BATCH_ENABLED=true`).
///
/// Keeping the datasource decoupled from the concrete implementation
/// preserves Dependency Inversion: the choice between unitary and batch
/// dispatch is a DI concern, not a business one.
// PR-I keeps a single method; future variants (`cancel`, `flushAll`) may
// add more, at which point removing this ignore is appropriate.
// ignore: one_member_abstracts
abstract interface class AgentCommandSender {
  Future<Map<String, dynamic>> send({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  });
}
