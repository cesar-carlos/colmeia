import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/agent_latency_oracle.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';

/// Glue that subscribes to [ConsumerSocketConnection] state transitions
/// and [SocketCommandDispatcher] outcomes and feeds them into a
/// [SocketChannelMetrics] instance. Owning the subscriptions in a single
/// place keeps the dispatcher and the connection free of metric concerns.
///
/// Designed as a `start()` / `dispose()` pair so DI can keep the
/// listener as a lazy singleton and the bootstrap can decide when to
/// kick it off (typically right after `setupDependencies()`).
///
/// See `docs/Features/socket_channel_performance_review.md` §5.8.
class SocketMetricsListener {
  SocketMetricsListener({
    required ConsumerSocketConnection connection,
    required SocketCommandDispatcher dispatcher,
    required SocketChannelMetrics metrics,
    AgentLatencyOracle? latencyOracle,
  }) : _connection = connection,
       _dispatcher = dispatcher,
       _metrics = metrics,
       _latencyOracle = latencyOracle;

  final ConsumerSocketConnection _connection;
  final SocketCommandDispatcher _dispatcher;
  final SocketChannelMetrics _metrics;
  final AgentLatencyOracle? _latencyOracle;

  StreamSubscription<ConsumerSocketConnectionState>? _statesSub;
  StreamSubscription<AgentCommandOutcome>? _outcomesSub;

  DateTime? _connectingStartedAt;
  bool _isStarted = false;
  bool _isDisposed = false;

  /// Idempotent. Safe to call from `bootstrap.dart` right after the DI
  /// registers the dispatcher / connection.
  void start() {
    if (_isStarted || _isDisposed) {
      return;
    }
    _isStarted = true;
    _statesSub = _connection.states().listen(_onState);
    _outcomesSub = _dispatcher.outcomes().listen(_onOutcome);
    AppLogger.debug(
      'SocketMetricsListener attached',
      context: const <String, Object?>{
        'component': 'SocketMetricsListener',
      },
    );
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _statesSub?.cancel();
    await _outcomesSub?.cancel();
    _statesSub = null;
    _outcomesSub = null;
  }

  // ----- Internals -----

  void _onState(ConsumerSocketConnectionState state) {
    switch (state) {
      case ConsumerSocketConnecting():
        _connectingStartedAt = DateTime.now();
      case ConsumerSocketConnected():
        final start = _connectingStartedAt;
        if (start != null) {
          _metrics.recordHandshake(elapsed: DateTime.now().difference(start));
          _connectingStartedAt = null;
        }
      case ConsumerSocketDisconnected(:final reason):
        _connectingStartedAt = null;
        _metrics.recordReconnect(reason: reason ?? 'disconnected');
      case ConsumerSocketError(:final transient, :final cause):
        _connectingStartedAt = null;
        _metrics.recordReconnect(
          reason: transient ? 'transient_error' : 'fatal_error',
        );
        // One breadcrumb is more useful than a histogram entry alone.
        AppLogger.warning(
          'Consumer socket transitioned to error state',
          context: <String, Object?>{
            'component': 'SocketMetricsListener',
            'transient': transient,
          },
          error: cause,
        );
      case ConsumerSocketUnauthorized():
        _connectingStartedAt = null;
        _metrics.recordReconnect(reason: 'unauthorized');
    }
  }

  void _onOutcome(AgentCommandOutcome outcome) {
    _metrics
      ..recordOutcome(outcome: outcome)
      ..recordDispatch(
        agentId: outcome.agentId,
        method: outcome.method,
        elapsed: outcome.elapsed,
      );
    final method = outcome.method;
    final oracle = _latencyOracle;
    if (oracle != null && method != null && outcome is AgentCommandSuccess) {
      // Only successful round-trips contribute to the latency oracle —
      // failures (timeouts, disconnects) would skew the EWMA upwards and
      // would cause the dispatcher to suggest ever-growing timeouts.
      oracle.record(
        agentId: outcome.agentId,
        method: method,
        elapsed: outcome.elapsed,
      );
    }
  }
}
