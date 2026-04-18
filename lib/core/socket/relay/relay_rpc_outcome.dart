import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';

/// Broadcast outcome emitted by `RelayCommandDispatcher.outcomes()`. Exactly
/// one event per `sendUnary` invocation, mirroring `AgentCommandOutcome` for
/// the legacy `agents:command` channel.
sealed class RelayRpcOutcome {
  const RelayRpcOutcome({
    required this.agentId,
    required this.conversationId,
    required this.clientRequestId,
    required this.requestId,
    required this.observedAt,
    required this.elapsed,
    this.method,
  });

  final String agentId;
  final String? conversationId;
  final String clientRequestId;

  /// Server-assigned id received in `relay:rpc.accepted`. May be `null` when
  /// the request was rejected before the hub generated one.
  final String? requestId;
  final DateTime observedAt;
  final Duration elapsed;
  final String? method;
}

final class RelayRpcSuccess extends RelayRpcOutcome {
  const RelayRpcSuccess({
    required super.agentId,
    required super.conversationId,
    required super.clientRequestId,
    required super.requestId,
    required super.observedAt,
    required super.elapsed,
    super.method,
    this.deduplicated = false,
    this.replayed = false,
  });

  /// `relay:rpc.accepted` indicated the response was served from the
  /// idempotency cache.
  final bool deduplicated;

  /// Idempotent replay (same `client_request_id`, response cached on hub).
  final bool replayed;
}

final class RelayRpcFailure extends RelayRpcOutcome {
  const RelayRpcFailure({
    required super.agentId,
    required super.conversationId,
    required super.clientRequestId,
    required super.requestId,
    required super.observedAt,
    required super.elapsed,
    required this.exception,
    super.method,
  });

  final RelayDispatchException exception;
}
