import 'dart:async';

import 'package:colmeia/app/authentication_gate.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:flutter/widgets.dart';

/// Observer that wires the consumer Socket connection lifecycle to:
///
/// 1. The Flutter app lifecycle (`paused`/`detached` -> `pause()`,
///    `resumed` -> `resume()`). Mobile economy: we drop the socket while
///    the app is in background.
/// 2. The auth lifecycle (post-login warm-up): when the
///    [AuthenticationGate] moves from "no session" to "authenticated" and
///    the build is configured with `AGENT_BRIDGE_TRANSPORT=socket` and
///    `SOCKET_WARM_UP_AFTER_LOGIN=true`, we eagerly call
///    [ConsumerSocketConnection.connect] (via `resume()`) so the first SQL
///    query does not pay the handshake cost.
/// 3. The cold-start / hot-reload race: if the auth restore completes
///    BEFORE this observer mounts (so the auth gate is already
///    authenticated at `initState`), we still warm the socket up once,
///    instead of relying solely on the transition listener (which would
///    miss the edge entirely).
///
/// Designed as a stateful widget so it can be plugged inside `MultiProvider`
/// in `bootstrap.dart`. SRP-conscious: only orchestration, no business
/// rules. Depends on the [AuthenticationGate] abstraction (not the concrete
/// `AuthController`) to keep the lifecycle logic decoupled from the auth
/// feature. See `docs/Features/socket_consumer_channel_plan.md` §10.
///
/// REST-only builds can omit [connection] entirely (it is nullable). In
/// that mode the observer becomes a no-op for every socket-bound action,
/// which avoids materialising `ConsumerSocketConnection` on REST builds.
class SocketLifecycleObserver extends StatefulWidget {
  const SocketLifecycleObserver({
    required this.authGate,
    required this.transport,
    required this.warmUpAfterLogin,
    required this.child,
    this.connection,
    super.key,
  });

  /// The consumer socket connection. May be `null` on REST-only builds; in
  /// that case the observer skips every pause/resume call regardless of
  /// other inputs (the [transport] gate is the canonical authority).
  final ConsumerSocketConnection? connection;
  final AuthenticationGate authGate;
  final AgentBridgeTransport transport;
  final bool warmUpAfterLogin;
  final Widget child;

  @override
  State<SocketLifecycleObserver> createState() =>
      _SocketLifecycleObserverState();
}

class _SocketLifecycleObserverState extends State<SocketLifecycleObserver>
    with WidgetsBindingObserver {
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wasAuthenticated = widget.authGate.isAuthenticated;
    widget.authGate.addListener(_onAuthChanged);

    // Cold-start / hot-reload race fix: if the auth gate is already
    // authenticated by the time this observer mounts (the restore future
    // resolved before initState), the false->true transition listener will
    // never fire and the socket would stay cold until the first query.
    // Warm it up here so the post-login UX is consistent with the live
    // login transition path.
    if (_shouldWarmUpEagerly()) {
      unawaited(_safeResume(reason: 'mount_already_authenticated'));
    }
  }

  @override
  void dispose() {
    widget.authGate.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isSocketTransport) {
      return;
    }
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_safePause());
      case AppLifecycleState.resumed:
        if (widget.authGate.isAuthenticated) {
          unawaited(_safeResume(reason: 'app_resumed'));
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No-op: transitions through these states do not require touching
        // the socket; pause/resume cover the actionable cases.
        break;
    }
  }

  void _onAuthChanged() {
    final isAuthenticated = widget.authGate.isAuthenticated;
    final transitionedToAuthenticated = !_wasAuthenticated && isAuthenticated;
    final transitionedToSignedOut = _wasAuthenticated && !isAuthenticated;
    _wasAuthenticated = isAuthenticated;

    if (transitionedToSignedOut) {
      // Sign-out only needs to touch the socket on socket builds. On REST
      // builds there is no live connection to release.
      if (_isSocketTransport) {
        unawaited(_safePause(reason: 'signed_out'));
      }
      return;
    }

    if (transitionedToAuthenticated && _shouldWarmUpEagerly()) {
      unawaited(_safeResume(reason: 'post_login_warm_up'));
    }
  }

  bool get _isSocketTransport =>
      widget.transport == AgentBridgeTransport.socket &&
      widget.connection != null;

  bool _shouldWarmUpEagerly() {
    return _isSocketTransport &&
        widget.warmUpAfterLogin &&
        widget.authGate.isAuthenticated;
  }

  Future<void> _safePause({String reason = 'app_paused'}) async {
    final connection = widget.connection;
    if (connection == null) {
      return;
    }
    try {
      await connection.pause();
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'SocketLifecycleObserver pause failed',
        context: <String, Object?>{
          'component': 'SocketLifecycleObserver',
          'reason': reason,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _safeResume({required String reason}) async {
    final connection = widget.connection;
    if (connection == null) {
      return;
    }
    try {
      await connection.resume();
      AppLogger.debug(
        'Consumer socket warm-up requested',
        context: <String, Object?>{
          'component': 'SocketLifecycleObserver',
          'reason': reason,
        },
      );
    } on Object catch (error, stackTrace) {
      // Connection failures are already logged inside ConsumerSocketConnection;
      // we keep one breadcrumb here so it is easy to correlate UX impact.
      AppLogger.warning(
        'SocketLifecycleObserver resume failed',
        context: <String, Object?>{
          'component': 'SocketLifecycleObserver',
          'reason': reason,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
