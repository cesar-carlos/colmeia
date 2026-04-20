import 'package:socket_io_client/socket_io_client.dart' as io;

/// Port that wraps `IO.io(...)` so tests can substitute a fake socket without
/// touching the actual Socket.IO transport.
///
/// See `docs/Features/consumer_socket_connection_design.md` §5.
// PR-A keeps a single method; Phase 2 may add a streaming-aware variant.
// ignore: one_member_abstracts
abstract interface class SocketIoClientFactory {
  /// Creates a freshly configured `IO.Socket`. Auto-connect and the built-in
  /// reconnection are intentionally disabled so the consumer connection can
  /// orchestrate its own backoff with token refresh on auth failures.
  io.Socket create({required String url, required String accessToken});
}

class DefaultSocketIoClientFactory implements SocketIoClientFactory {
  const DefaultSocketIoClientFactory();

  @override
  io.Socket create({required String url, required String accessToken}) {
    return io.io(
      url,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .disableReconnection()
          .setAuth(<String, dynamic>{'token': accessToken})
          .build(),
    );
  }
}
