import 'package:colmeia/core/socket/agent_command_outcome.dart';

/// Single point that emits `agents:command` events on the consumer socket
/// and awaits the correlated `agents:command_response`.
///
/// Detailed contract: `docs/Features/socket_command_dispatcher_design.md` §2.
abstract interface class SocketCommandDispatcher {
  /// Dispatches a single JSON-RPC command and waits for the correlated
  /// response. The [body] must already be in the same shape used by the
  /// REST endpoint `POST /api/v1/agents/commands` — produced by
  /// `AgentSqlExecuteRequestToBridgeBody`.
  ///
  /// [agentId] is the routing target; reserved for outcome metadata and
  /// future per-agent gating (P1 review §5.5).
  ///
  /// [rpcId] is the JSON-RPC `command.id` and is used by the correlator
  /// to match the response. Callers MUST provide a unique value (UUID v4).
  ///
  /// Throws:
  /// - `SocketDispatchUnauthorized` when the socket cannot reach
  ///   `connected` due to auth.
  /// - `SocketDispatchTimeout` when the response does not arrive within
  ///   the effective timeout.
  /// - `SocketDispatchDisconnected` when the socket drops during the
  ///   request.
  /// - `SocketDispatchAppError` (sealed under `SocketDispatchException`)
  ///   for server-emitted `app:error` (e.g. `RATE_LIMITED`,
  ///   `AGENT_ACCESS_DENIED`, `SERVICE_UNAVAILABLE`).
  /// - `SocketDispatchDuplicateId` when [rpcId] is already pending.
  /// When [coalesce] is `true` (default) and another in-flight call has
  /// the canonical same body (`SocketCoalesceKey`), this method returns
  /// **the same Future** without firing a second `agents:command` emit.
  /// Pass `false` to force every call to hit the wire — useful for
  /// non-idempotent operations and for tests that need ordering control.
  Future<Map<String, dynamic>> sendAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
    bool coalesce = true,
  });

  /// Broadcast stream of dispatch outcomes: success / offline / auth /
  /// transient. Emitted exactly once per `sendAgentsCommand` invocation.
  Stream<AgentCommandOutcome> outcomes();

  /// PR-J: cancel a pending request by [rpcId]. The associated
  /// `Future` settled by `sendAgentsCommand` errors with
  /// `SocketDispatchCancelled`; the outcome stream emits a single
  /// `AgentCommandFailedTransient` with `reasonCode: 'cancelled'`.
  ///
  /// Idempotent: cancelling an unknown or already-completed `rpcId` is
  /// a silent no-op. Useful as the dispose-time hook for controllers
  /// that hold a `SocketCommandCancelToken`, and as the building block
  /// for future `sql.cancel` integration on streaming requests.
  void cancel(String rpcId, {String reason});

  Future<void> dispose();
}
