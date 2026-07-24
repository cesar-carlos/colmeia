import 'dart:async';

import 'package:colmeia/app/authentication_gate.dart';
import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_app_error_codes.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/consumer_socket_idle_keepalive.dart';
import 'package:flutter/widgets.dart';

/// Observer that wires the consumer Socket connection lifecycle to:
///
/// 1. The Flutter app lifecycle (`paused`/`detached` -> `pause()`,
///    `resumed` -> `resume()`). Mobile economy: we drop the socket while
///    the app is in background.
/// 2. The auth lifecycle (post-login warm-up): when the
///    [AuthenticationGate] moves from "no session" to "authenticated" and
///    the build wires a non-null [connection] (socket bridge and/or relay
///    over `/consumers`) with `SOCKET_WARM_UP_AFTER_LOGIN=true`, we eagerly
///    call [ConsumerSocketConnection.connect] (via `resume()`) so the first
///    SQL query does not pay the handshake cost.
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
    this.idleKeepaliveInterval = Duration.zero,
    super.key,
  });

  /// The consumer socket connection. May be `null` when no `/consumers`
  /// session should be managed (typical REST-only builds without relay).
  /// When non-null, pause/resume/warm-up run regardless of [transport] so
  /// relay-over-socket (`SOCKET_RELAY_ENABLED` with REST bridge) still
  /// respects app lifecycle.
  final ConsumerSocketConnection? connection;
  final AuthenticationGate authGate;
  final AgentBridgeTransport transport;
  final bool warmUpAfterLogin;

  /// When positive, emits a lightweight inbound touch while the app is
  /// foregrounded and the socket is connected (hub idle default is 30 min).
  final Duration idleKeepaliveInterval;
  final Widget child;

  @override
  State<SocketLifecycleObserver> createState() =>
      _SocketLifecycleObserverState();
}

class _SocketLifecycleObserverState extends State<SocketLifecycleObserver>
    with WidgetsBindingObserver {
  bool _wasAuthenticated = false;

  /// Tracks current app lifecycle state so the connection-state listener
  /// can guard reconnect attempts against background/detached conditions.
  AppLifecycleState? _currentLifecycleState;

  StreamSubscription<ConsumerSocketConnectionState>? _connectionStatesSub;
  ConsumerSocketIdleKeepalive? _idleKeepalive;
  Timer? _recoverTimer;

  /// Minimum gap between automatic reconnects triggered by unexpected
  /// server-side disconnects while the app stays in foreground.
  static const _unexpectedReconnectCooldown = Duration(seconds: 3);

  DateTime? _lastUnexpectedReconnectAt;

  /// Reasons that identify an intentional disconnect initiated by the app
  /// or a hub-forced terminal `app:error`. Unexpected server-side
  /// disconnects will carry a Socket.IO transport reason (e.g.
  /// "io server disconnect", "transport close") or null, and must trigger
  /// an automatic reconnect — except when the reason is hub-forced.
  static const _intentionalDisconnectReasons = <String>{
    'app_paused',
    'signed_out',
    'session_invalidated',
    'disposed',
    'disconnect',
  };

  bool _isIntentionalDisconnectReason(String? reason) {
    if (reason == null) {
      return false;
    }
    return _intentionalDisconnectReasons.contains(reason) ||
        ConsumerSocketAppErrorCodes.isHubForcedDisconnectReason(reason);
  }

  bool get _isAppInForeground {
    final s = _currentLifecycleState;
    // null means no lifecycle event received yet — app started in foreground.
    return s == null || s == AppLifecycleState.resumed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wasAuthenticated = widget.authGate.isAuthenticated;
    widget.authGate.addListener(_onAuthChanged);

    if (_shouldManageSocket) {
      _connectionStatesSub = widget.connection!.states().listen(
        _onConnectionStateChanged,
      );
      if (widget.idleKeepaliveInterval > Duration.zero) {
        _idleKeepalive = ConsumerSocketIdleKeepalive(
          connection: widget.connection!,
          interval: widget.idleKeepaliveInterval,
        )..start();
      }
    }

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
    _cancelScheduledRecover();
    unawaited(_idleKeepalive?.dispose() ?? Future<void>.value());
    _idleKeepalive = null;
    unawaited(_connectionStatesSub?.cancel() ?? Future<void>.value());
    _connectionStatesSub = null;
    widget.authGate.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentLifecycleState = state;
    if (!_shouldManageSocket) {
      return;
    }
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cancelScheduledRecover();
        _idleKeepalive?.stop();
        unawaited(_safePause());
      case AppLifecycleState.resumed:
        if (widget.authGate.isAuthenticated) {
          final connection = widget.connection;
          if (connection != null && connection.state is ConsumerSocketError) {
            unawaited(_safeResume(reason: 'recover_from_socket_error'));
          } else {
            unawaited(_safeResume(reason: 'app_resumed'));
          }
          _idleKeepalive?.start();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No-op: transitions through these states do not require touching
        // the socket; pause/resume cover the actionable cases.
        break;
    }
  }

  /// Reacts to unexpected server-side disconnects / exhausted reconnects
  /// by triggering a reconnect.
  ///
  /// Only fires when:
  /// - The disconnect reason is NOT one of the known client-initiated reasons
  ///   (app pause, sign-out, dispose, explicit disconnect), OR the state is a
  ///   non-transient [ConsumerSocketError] (reconnect attempts exhausted).
  /// - The user is currently authenticated.
  /// - The app is in foreground.
  ///
  /// `ConsumerSocketConnection.connect()` is single-flight and owns the
  /// backoff/retry loop internally, so concurrent or redundant calls here
  /// are safe. Transient [ConsumerSocketError] is ignored because the
  /// connection layer is already retrying.
  void _onConnectionStateChanged(ConsumerSocketConnectionState state) {
    if (state is ConsumerSocketConnected) {
      _lastUnexpectedReconnectAt = null;
      _cancelScheduledRecover();
      return;
    }
    if (!widget.authGate.isAuthenticated) {
      return;
    }
    if (!_isAppInForeground) {
      return;
    }

    if (state is ConsumerSocketError) {
      if (state.transient) {
        return;
      }
      _scheduleRecover(reason: 'recover_from_reconnect_exhausted');
      return;
    }

    if (state is! ConsumerSocketDisconnected) {
      return;
    }
    final reason = state.reason;
    if (_isIntentionalDisconnectReason(reason)) {
      return;
    }
    _scheduleRecover(
      reason: 'unexpected_disconnect',
      disconnectReason: reason,
    );
  }

  void _scheduleRecover({
    required String reason,
    String? disconnectReason,
  }) {
    final now = DateTime.now();
    final last = _lastUnexpectedReconnectAt;
    if (last != null && now.difference(last) < _unexpectedReconnectCooldown) {
      return;
    }
    _lastUnexpectedReconnectAt = now;
    _cancelScheduledRecover();
    AppLogger.debug(
      'SocketLifecycleObserver: scheduling reconnect',
      context: <String, Object?>{
        'component': 'SocketLifecycleObserver',
        'reason': reason,
        'disconnectReason': ?disconnectReason,
      },
    );
    // Defer past any in-flight connect single-flight so we do not race the
    // same exhausted attempt. Cooldown already bounds how often we fire.
    _recoverTimer = Timer(_unexpectedReconnectCooldown, () {
      _recoverTimer = null;
      if (!mounted || !widget.authGate.isAuthenticated || !_isAppInForeground) {
        return;
      }
      unawaited(_safeResume(reason: reason));
    });
  }

  void _cancelScheduledRecover() {
    _recoverTimer?.cancel();
    _recoverTimer = null;
  }

  void _onAuthChanged() {
    final isAuthenticated = widget.authGate.isAuthenticated;
    final transitionedToAuthenticated = !_wasAuthenticated && isAuthenticated;
    final transitionedToSignedOut = _wasAuthenticated && !isAuthenticated;
    _wasAuthenticated = isAuthenticated;

    if (transitionedToSignedOut) {
      // Sign-out only needs to touch the socket when a live connection is
      // wired (socket bridge and/or relay).
      _cancelScheduledRecover();
      if (_shouldManageSocket) {
        unawaited(_safePause(reason: 'signed_out'));
      }
      return;
    }

    if (transitionedToAuthenticated && _shouldWarmUpEagerly()) {
      unawaited(_safeResume(reason: 'post_login_warm_up'));
    }
  }

  bool get _shouldManageSocket => widget.connection != null;

  bool _shouldWarmUpEagerly() {
    return _shouldManageSocket &&
        widget.warmUpAfterLogin &&
        widget.authGate.isAuthenticated;
  }

  Future<void> _safePause({String reason = 'app_paused'}) async {
    final connection = widget.connection;
    if (connection == null) {
      return;
    }
    try {
      await connection.pause(reason: reason);
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
