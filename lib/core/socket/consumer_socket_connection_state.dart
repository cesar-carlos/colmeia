/// High-level state of the single consumer Socket.IO connection.
///
/// Sealed because consumers (controllers, presence stream) read transitions
/// via exhaustive `switch`. Carrying contextual data per state avoids
/// scattering optional fields on the connection itself.
///
/// Valid transitions documented in
/// `docs/Features/consumer_socket_connection_design.md` §2.
sealed class ConsumerSocketConnectionState {
  const ConsumerSocketConnectionState();
}

final class ConsumerSocketDisconnected extends ConsumerSocketConnectionState {
  const ConsumerSocketDisconnected({this.reason});
  final String? reason;
}

final class ConsumerSocketConnecting extends ConsumerSocketConnectionState {
  const ConsumerSocketConnecting({required this.attempt});

  /// 1-based attempt counter for this connect cycle.
  final int attempt;
}

final class ConsumerSocketConnected extends ConsumerSocketConnectionState {
  const ConsumerSocketConnected({
    required this.socketId,
    required this.handshakeAt,
    this.hubInstanceId,
  });
  final String socketId;
  final DateTime handshakeAt;
  final String? hubInstanceId;
}

final class ConsumerSocketError extends ConsumerSocketConnectionState {
  const ConsumerSocketError({
    required this.message,
    required this.transient,
    this.cause,
    this.stackTrace,
  });
  final String message;
  final bool transient;
  final Object? cause;
  final StackTrace? stackTrace;
}

/// Terminal state: a refresh attempt already failed during handshake.
/// New sessions require a fresh login (the controller should redirect to
/// the login screen).
final class ConsumerSocketUnauthorized extends ConsumerSocketConnectionState {
  const ConsumerSocketUnauthorized();
}
