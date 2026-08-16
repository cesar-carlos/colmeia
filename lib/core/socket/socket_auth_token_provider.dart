import 'dart:async';

import 'package:colmeia/core/network/auth_refresh_coordinator.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/network/auth_session_events.dart';

/// Port that the socket layer uses to read or refresh the access token used in
/// the `/consumers` handshake. Keeping this as an interface lets `core/socket/`
/// stay decoupled from `features/auth/`.
///
/// See `docs/Features/consumer_socket_connection_design.md` §4.
abstract interface class SocketAuthTokenProvider {
  /// Returns the current access token, or `null` when the session is missing.
  /// Does **not** trigger a refresh.
  Future<String?> readAccessToken();

  /// Performs the single-flight refresh delegated to
  /// [AuthRefreshCoordinator]. Returns the new token or `null` when the
  /// session must be invalidated.
  Future<String?> refreshAccessToken();

  /// Broadcast stream that fires when the session is invalidated outside the
  /// socket layer (e.g., explicit logout). The socket connection observes this
  /// stream to disconnect proactively.
  Stream<void> sessionInvalidations();
}

/// Default implementation backed by the existing auth coordinators.
class SessionSocketAuthTokenProvider implements SocketAuthTokenProvider {
  SessionSocketAuthTokenProvider({
    required this._sessionAccessor,
    required this._refreshCoordinator,
    required this._sessionEvents,
  });

  final AuthSessionAccessor _sessionAccessor;
  final AuthRefreshCoordinator _refreshCoordinator;
  final AuthSessionEvents _sessionEvents;

  @override
  Future<String?> readAccessToken() async {
    final session = await _sessionAccessor.read();
    final token = session?.accessToken;
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  @override
  Future<String?> refreshAccessToken() {
    return _refreshCoordinator.refreshAccessToken();
  }

  @override
  Stream<void> sessionInvalidations() => _sessionEvents.stream
      .where((event) => event.type == AuthSessionEventType.invalidated)
      .map<void>((_) {});
}
