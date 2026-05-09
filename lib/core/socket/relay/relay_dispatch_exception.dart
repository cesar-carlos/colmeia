/// Failures raised by the relay dispatcher. Kept separate from
/// `SocketDispatchException` because the relay layer carries extra context
/// (`conversationId`, `clientRequestId`) and a richer set of terminal codes
/// (`backpressure_aborted`, `circuit_open`, …).
///
/// JSON-RPC payload errors that travel inside `relay:rpc.response` /
/// `relay:rpc.complete` remain represented by `AgentSqlRpcException` in the
/// repository layer, exactly like the REST and `agents:command` paths.
sealed class RelayDispatchException implements Exception {
  const RelayDispatchException({
    required this.message,
    required this.code,
    this.conversationId,
    this.clientRequestId,
    this.cause,
    this.stackTrace,
  });

  final String message;

  /// Stable identifier consumable by metrics / Sentry breadcrumbs.
  final String code;

  /// Conversation that surfaced the failure (when known).
  final String? conversationId;

  /// JSON-RPC `id` provided by the caller; mirrors the hub's
  /// `client_request_id` for idempotency.
  final String? clientRequestId;

  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'RelayDispatchException($code'
      '${conversationId != null ? ', conv=$conversationId' : ''}'
      '${clientRequestId != null ? ', cri=$clientRequestId' : ''}'
      '): $message';
}

/// Conversation could not be opened (missing socket, hub overload,
/// `relay:conversation.started` arrived with `success: false`).
final class RelayConversationStartFailure extends RelayDispatchException {
  const RelayConversationStartFailure({
    required super.message,
    super.code = 'conversation_start_failed',
    super.cause,
    super.stackTrace,
  });
}

/// Conversation drop while a request was still pending. Callers should treat
/// this as transient — the manager will reopen on the next call.
final class RelayConversationLost extends RelayDispatchException {
  const RelayConversationLost({
    required super.message,
    super.conversationId,
    super.clientRequestId,
    super.cause,
    super.stackTrace,
  }) : super(code: 'conversation_lost');
}

/// `relay:rpc.accepted` came back with `success: false` (validation,
/// idempotency reject, rate-limited, …). The exception carries the server
/// `error.code` so the repository can map it to the right `AppFailure`.
final class RelayRequestRejected extends RelayDispatchException {
  const RelayRequestRejected({
    required super.message,
    required String serverCode,
    this.retryAfter,
    super.conversationId,
    super.clientRequestId,
  }) : super(code: serverCode);

  /// Optional hub backoff hint propagated from `retryAfterMs` /
  /// `retry_after_ms` fields on relay rejection payloads.
  final Duration? retryAfter;
}

/// Hub closed the request stream with a terminal status other than
/// `completed` (e.g. `aborted`, `error`).
final class RelayStreamTerminated extends RelayDispatchException {
  const RelayStreamTerminated({
    required super.message,
    required String terminalStatus,
    super.conversationId,
    super.clientRequestId,
  }) : super(code: 'stream_$terminalStatus');
}

/// No `relay:rpc.response` / `relay:rpc.complete` arrived within the
/// configured window. Ends the pending future.
final class RelayRequestTimeout extends RelayDispatchException {
  const RelayRequestTimeout({
    required super.message,
    super.conversationId,
    super.clientRequestId,
  }) : super(code: 'timeout');
}

/// The PayloadFrame returned by the hub failed structural validation
/// (`enc != json`, gzip inflation, size cap). Surfaced as transient so the
/// caller can retry with a fresh request id.
final class RelayDecodeFailure extends RelayDispatchException {
  const RelayDecodeFailure({
    required super.message,
    super.code = 'decode_failed',
    super.conversationId,
    super.clientRequestId,
    super.cause,
    super.stackTrace,
  });
}

/// Caller passed a `clientRequestId` already in flight on the same
/// conversation. Reuse a different UUID.
final class RelayDuplicateRequestId extends RelayDispatchException {
  const RelayDuplicateRequestId({
    required super.message,
    required String super.conversationId,
    required String super.clientRequestId,
  }) : super(code: 'duplicate_request_id');
}

/// Dispatcher torn down (logout / app dispose) while the request was pending.
final class RelayDispatcherDisposed extends RelayDispatchException {
  const RelayDispatcherDisposed({
    required super.message,
    super.conversationId,
    super.clientRequestId,
  }) : super(code: 'dispatcher_disposed');
}
