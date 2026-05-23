import 'dart:async';
import 'dart:convert';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/observability/socket/socket_sql_metrics_appendix_port.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/agent_latency_oracle.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_rpc_outcome.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/agent_queries/data/repositories/metrics_agent_queries_repository.dart' show MetricsAgentQueriesRepository;
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
    RelayCommandDispatcher? relayDispatcher,
    PerAgentConcurrencyGate? concurrencyGate,
  }) : _connection = connection,
       _dispatcher = dispatcher,
       _metrics = metrics,
       _latencyOracle = latencyOracle,
       _relayDispatcher = relayDispatcher,
       _concurrencyGate = concurrencyGate;

  final ConsumerSocketConnection _connection;
  final SocketCommandDispatcher _dispatcher;
  final SocketChannelMetrics _metrics;
  final AgentLatencyOracle? _latencyOracle;
  final RelayCommandDispatcher? _relayDispatcher;
  final PerAgentConcurrencyGate? _concurrencyGate;

  StreamSubscription<ConsumerSocketConnectionState>? _statesSub;
  StreamSubscription<AgentCommandOutcome>? _outcomesSub;
  StreamSubscription<RelayRpcOutcome>? _relayOutcomesSub;

  SocketSqlMetricsAppendixProvider? _sqlAppendix;

  SocketSqlMetricsAppendixProvider? get sqlAppendix => _sqlAppendix;

  /// Wired after [MetricsAgentQueriesRepository] is registered so the
  /// listener stays free of feature imports.
  set sqlAppendix(SocketSqlMetricsAppendixProvider provider) {
    _sqlAppendix = provider;
  }

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
    final relay = _relayDispatcher;
    if (relay != null) {
      _relayOutcomesSub = relay.outcomes().listen(_onRelayOutcome);
    }
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
    await _relayOutcomesSub?.cancel();
    _statesSub = null;
    _outcomesSub = null;
    _relayOutcomesSub = null;
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
        _exportSessionSocketMetrics(
          socketEvent: 'disconnected',
          extra: <String, Object?>{
            'disconnectReason': reason ?? 'disconnected',
          },
        );
      case ConsumerSocketError(:final transient, :final cause):
        _connectingStartedAt = null;
        _metrics.recordReconnect(
          reason: transient ? 'transient_error' : 'fatal_error',
        );
        _exportSessionSocketMetrics(
          socketEvent: 'error',
          extra: <String, Object?>{'transient': transient},
        );
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
        _exportSessionSocketMetrics(socketEvent: 'unauthorized');
    }
  }

  void _exportSessionSocketMetrics({
    required String socketEvent,
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    final gate = _concurrencyGate;
    if (gate != null) {
      _metrics.lastGateSessionPeakSample =
          gate.sessionPeakMaxAgentInflight;
      gate.resetSessionConcurrencyPeak();
    }
    final snapshot = _metrics.snapshot();
    final compact = snapshot.toCompactSessionExport();
    final sqlAppendix = _sqlAppendix?.call();
    final context = <String, Object?>{
      'component': 'SocketMetricsListener',
      'socketEvent': socketEvent,
      ...extra,
      'socketSession': compact,
      if (sqlAppendix != null && sqlAppendix.isNotEmpty)
        'sqlSessionAppendix': sqlAppendix,
    };
    AppLogger.info(
      'Socket session metrics export',
      context: context,
    );
    _addSentryBreadcrumb(
      socketEvent: socketEvent,
      compact: compact,
      sqlAppendix: sqlAppendix,
      extra: extra,
    );
    if (kDebugMode) {
      final fields = snapshot.relayDebugLogFields();
      if (fields.isNotEmpty) {
        AppLogger.debug(
          'Socket metrics: relay diagnostics at $socketEvent',
          context: <String, Object?>{
            'component': 'SocketMetricsListener',
            'socketEvent': socketEvent,
            ...extra,
            ...fields,
          },
        );
      }
    }
  }

  void _addSentryBreadcrumb({
    required String socketEvent,
    required Map<String, Object?> compact,
    Map<String, Object?>? sqlAppendix,
    Map<String, Object?> extra = const {},
  }) {
    try {
      final encodable = <String, Object?>{
        'socketEvent': socketEvent,
        ...extra,
        'socketSession': compact,
        if (sqlAppendix != null && sqlAppendix.isNotEmpty)
          'sqlSessionAppendix': sqlAppendix,
      };
      var encoded = jsonEncode(encodable);
      if (encoded.length > 8000) {
        encoded = encoded.substring(0, 8000);
      }
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'socket.session_metrics',
            message: socketEvent,
            data: <String, dynamic>{'payload': encoded},
            level: SentryLevel.info,
          ),
        ),
      );
    } on Object catch (_) {
      // Sentry may be uninitialized in some tests / early boot paths.
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
      oracle.record(
        agentId: outcome.agentId,
        method: method,
        elapsed: outcome.elapsed,
      );
    }
  }

  void _onRelayOutcome(RelayRpcOutcome outcome) {
    _metrics
      ..recordRelayOutcome(outcome: outcome)
      ..recordRelayDispatch(
        agentId: outcome.agentId,
        method: outcome.method,
        elapsed: outcome.elapsed,
      );
    final method = outcome.method;
    final oracle = _latencyOracle;
    if (oracle != null && method != null && outcome is RelayRpcSuccess) {
      oracle.record(
        agentId: outcome.agentId,
        method: method,
        elapsed: outcome.elapsed,
      );
    }
  }
}
