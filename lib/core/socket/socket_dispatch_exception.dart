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

/// Hub rejected the handshake on `/consumers` because the JWT's
/// `role` is **not present** in `SOCKET_CONSUMER_ROLES`. Distinct
/// from [SocketDispatchUnauthorized] (which signals an actually
/// invalid / expired token) — this one means the token is fine but
/// the namespace policy on the server side excludes that role, so
/// refresh / re-login does NOT fix it. Mostly seen during rollouts
/// when the server-side env was not updated to include `client`
/// alongside `user,admin`.
///
/// Dispatch consumers SHOULD treat this as a permanent server
/// configuration error and either fall back to REST (see
/// `SocketWithRestFallbackAgentQueriesRemoteDataSource`) or surface
/// a hub-config user message instead of "Sua sessao expirou".
final class SocketDispatchNamespaceForbidden extends SocketDispatchException {
  const SocketDispatchNamespaceForbidden({
    required super.message,
    this.role,
    this.namespace,
    super.cause,
    super.stackTrace,
  }) : super(code: 'namespace_forbidden');

  /// Role from the JWT that the hub refused (e.g. `client`).
  /// `null` when the upstream payload did not include it.
  final String? role;

  /// Namespace that emitted the rejection (e.g. `/consumers`).
  /// `null` when not parseable from the upstream payload.
  final String? namespace;
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
