/// Failures raised by the socket dispatch layer that are NOT JSON-RPC errors.
///
/// JSON-RPC errors carried inside the response payload are represented by
/// `AgentSqlRpcException` in `features/agent_queries/data/...` and stay
/// identical to the REST path.
///
/// See `docs/Features/socket_command_dispatcher_design.md` §3.
sealed class SocketDispatchException implements Exception {
  const SocketDispatchException({
    required this.message,
    required this.code,
    this.cause,
    this.stackTrace,
  });

  final String message;

  /// Stable identifier for log / metric pivots and for the repository
  /// mapping to `AppFailure`.
  final String code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'SocketDispatchException($code): $message';
}

final class SocketDispatchTimeout extends SocketDispatchException {
  const SocketDispatchTimeout({
    required super.message,
    super.cause,
    super.stackTrace,
  }) : super(code: 'timeout');
}

final class SocketDispatchDisconnected extends SocketDispatchException {
  const SocketDispatchDisconnected({
    required super.message,
    super.cause,
    super.stackTrace,
  }) : super(code: 'disconnected');
}

final class SocketDispatchDecodeFailure extends SocketDispatchException {
  const SocketDispatchDecodeFailure({
    required super.message,
    super.cause,
    super.stackTrace,
  }) : super(code: 'decode_failed');
}

final class SocketDispatchDuplicateId extends SocketDispatchException {
  const SocketDispatchDuplicateId({required super.message})
    : super(code: 'duplicate_id');
}

final class SocketDispatchUnauthorized extends SocketDispatchException {
  const SocketDispatchUnauthorized({
    required super.message,
    super.cause,
    super.stackTrace,
  }) : super(code: 'unauthorized');
}

/// Server-emitted `app:error` mapped to a generic dispatch exception so the
/// repository layer can decide how to translate it to an `AppFailure`. The
/// `code` field carries the original server code (e.g. `AGENT_ACCESS_DENIED`,
/// `SERVICE_UNAVAILABLE`, `RATE_LIMITED`).
///
/// [retryAfter] is filled when the hub propagates a wait hint (`retryAfterMs`
/// in `SERVICE_UNAVAILABLE` payloads, or `error.data.retry_after_ms` for
/// rate-limited RPC errors). Callers SHOULD respect it before retrying.
final class SocketDispatchAppError extends SocketDispatchException {
  const SocketDispatchAppError({
    required super.message,
    required String serverCode,
    this.retryAfter,
  }) : super(code: serverCode);

  final Duration? retryAfter;
}

/// Caller (e.g. a `dispose()`-ing controller, or a screen leaving the
/// route) explicitly cancelled a pending dispatch via
/// `SocketCommandDispatcher.cancel(rpcId)` or a `SocketCommandCancelToken`.
/// Repositories should map this to a benign cancellation, not a failure
/// that surfaces an error UI.
final class SocketDispatchCancelled extends SocketDispatchException {
  const SocketDispatchCancelled({
    required super.message,
    super.cause,
    super.stackTrace,
  }) : super(code: 'cancelled');
}
