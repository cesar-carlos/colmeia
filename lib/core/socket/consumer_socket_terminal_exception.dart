/// Typed terminal failures surfaced by ConsumerSocketConnection.connect.
///
/// These replace the string-parsed StateError approach that the dispatchers
/// previously relied on, making the compiler verify exhaustiveness and
/// eliminating fragile message.startsWith checks across the dispatch layer.
///
/// Every subtype corresponds to exactly one non-retryable outcome from the
/// connection handshake loop. The dispatchers map each subtype to the
/// appropriate SocketDispatchException.
sealed class ConsumerSocketTerminalException implements Exception {
  const ConsumerSocketTerminalException({required this.message});
  final String message;

  @override
  String toString() => 'ConsumerSocketTerminalException($message)';
}

/// ConsumerSocketConnectCancelled: connect() was cancelled because
/// disconnect() / pause() was called while a connection attempt was in progress.
final class ConsumerSocketConnectCancelled
    extends ConsumerSocketTerminalException {
  const ConsumerSocketConnectCancelled({
    required super.message,
    required this.reason,
  });

  final String reason;
}

/// All reconnect attempts failed without a permanent auth or namespace error.
/// The connection has exhausted the configured maxReconnectAttempts.
final class ConsumerSocketReconnectExhausted
    extends ConsumerSocketTerminalException {
  const ConsumerSocketReconnectExhausted({
    required super.message,
    required this.cause,
  });

  final Object cause;
}

/// The JWT is missing, invalid, or could not be refreshed. A fresh login is
/// required; retrying the same token will not help.
final class ConsumerSocketAuthFailed extends ConsumerSocketTerminalException {
  const ConsumerSocketAuthFailed({
    required super.message,
    required this.reason,
  });

  final String reason;
}

/// The hub's namespace policy (SOCKET_CONSUMER_ROLES) excludes the JWT role.
/// Retrying or refreshing the token will NOT fix this — only a server-side
/// config change + restart can. The upstream fallback datasource should pivot
/// to REST for the rest of the session.
final class ConsumerSocketNamespaceForbidden
    extends ConsumerSocketTerminalException {
  const ConsumerSocketNamespaceForbidden({
    required super.message,
    this.role,
    this.namespace,
  });

  /// Role from the JWT that the hub refused (e.g. `client`).
  final String? role;

  /// Namespace that emitted the rejection (e.g. `/consumers`).
  final String? namespace;
}
