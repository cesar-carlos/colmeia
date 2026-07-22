import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:uuid/uuid.dart';

/// Emits a lightweight inbound Socket event so the hub idle clock does not
/// expire long foreground `/consumers` sessions.
///
/// Hub only refreshes idle on **valid** client-initiated events
/// (`socket:event.subscribe` is one of them). Malformed payloads and
/// overload `503` rejections do **not** renew the clock. See
/// `docs/plug_server/socket/socket_client_sdk.md` (Consumer idle timeout).
///
/// Disabled when [interval] is `Duration.zero` or negative.
class ConsumerSocketIdleKeepalive {
  ConsumerSocketIdleKeepalive({
    required ConsumerSocketConnection connection,
    required this.interval,
    this.eventName = defaultEventName,
    Uuid uuid = const Uuid(),
  }) : _connection = connection,
       _uuid = uuid;

  /// Reserved custom event used only as an idle touch (subscribe/unsubscribe).
  static const String defaultEventName = 'client:custom.colmeia.idle.keepalive';

  final ConsumerSocketConnection _connection;
  final Duration interval;
  final String eventName;
  final Uuid _uuid;

  StreamSubscription<ConsumerSocketConnectionState>? _statesSub;
  Timer? _timer;
  bool _disposed = false;

  bool get isActive => _timer != null;

  /// Starts listening to connection state. Idempotent.
  void start() {
    if (_disposed || interval <= Duration.zero) {
      return;
    }
    _statesSub ??= _connection.states().listen(_onState);
    try {
      if (_connection.isConnected) {
        _armTimer();
      }
    } on Object {
      // Connection may not expose isConnected yet (tests / mid-handshake);
      // the Connected state event will arm the timer.
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    stop();
    await _statesSub?.cancel();
    _statesSub = null;
  }

  void _onState(ConsumerSocketConnectionState state) {
    if (state is ConsumerSocketConnected) {
      _armTimer();
      return;
    }
    stop();
  }

  void _armTimer() {
    _timer?.cancel();
    if (_disposed || interval <= Duration.zero) {
      return;
    }
    _timer = Timer.periodic(interval, (_) => _touch());
  }

  void _touch() {
    if (!_connection.isConnected) {
      stop();
      return;
    }
    try {
      final socket = _connection.raw;
      final requestId = _uuid.v4();
      socket
        ..emit('socket:event.subscribe', <String, Object?>{
          'requestId': requestId,
          'eventName': eventName,
        })
        // Immediately release the subscription slot — the subscribe alone
        // refreshed hub lastSeenAt.
        ..emit('socket:event.unsubscribe', <String, Object?>{
          'requestId': _uuid.v4(),
          'eventName': eventName,
        });
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Consumer socket idle keepalive touch failed',
        context: const <String, Object?>{
          'component': 'ConsumerSocketIdleKeepalive',
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
