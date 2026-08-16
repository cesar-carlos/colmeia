import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';

/// Callback that resolves the agent ids whose relay conversation should be
/// opened ahead of the first SQL fan-out. Returning an empty list disables
/// pre-warming for the current session.
typedef RelayPreWarmAgentIdsLoader = Future<List<String>> Function();

/// Opens relay conversations for the user's known agents as soon as the
/// consumer socket reaches the connected state, so the first cross-agent
/// `mergeAll` wave does not pay one synchronous
/// `relay:conversation.start` round-trip per distinct agent.
///
/// Observability: this class is best-effort. Every failure is logged at
/// debug level and swallowed; the regular lazy path inside
/// [RelayConversationManager.obtain] still runs on first RPC if the
/// pre-warm did not succeed.
///
/// Lifecycle:
/// - Subscribes to [ConsumerSocketConnection.states] in the constructor.
/// - On every transition to [ConsumerSocketConnected], schedules a single
///   pre-warm sweep (single-flight). Concurrent transitions are coalesced.
/// - On every disconnect / error / unauthorized, bumps a generation counter
///   so any in-flight sweep short-circuits before issuing further
///   [RelayConversationManager.obtain] calls — the relay manager already
///   drops live conversations on disconnect, so re-issuing `start` against
///   a stale socket would race with the next reconnect sweep and could
///   leave orphan `conversationId`s on the hub.
class RelayConversationPreWarmer {
  RelayConversationPreWarmer({
    required this._connection,
    required this._conversationManager,
    required this._loadAgentIds,
    int maxAgents = _defaultMaxAgents,
    int maxConcurrentStarts = _defaultMaxConcurrentStarts,
  }) : _maxAgents = _checkPositive(maxAgents, 'maxAgents'),
       _maxConcurrentStarts = _checkPositive(
         maxConcurrentStarts,
         'maxConcurrentStarts',
       ) {
    _stateSub = _connection.states().listen(_onConnectionState);
  }

  /// Mirrors the default `mergeAllConcurrency` of the across-agent executors.
  /// Larger sweeps would just queue against the per-agent gate without any
  /// extra warming benefit on the first wave.
  static const int _defaultMaxAgents = 8;

  /// Caps how many `relay:conversation.start` round-trips fire at once so a
  /// reconnect does not stampede the hub.
  static const int _defaultMaxConcurrentStarts = 2;

  static int _checkPositive(int value, String name) {
    if (value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        'must be positive',
      );
    }
    return value;
  }

  final ConsumerSocketConnection _connection;
  final RelayConversationManager _conversationManager;
  final RelayPreWarmAgentIdsLoader _loadAgentIds;
  final int _maxAgents;
  final int _maxConcurrentStarts;

  // ignore: cancel_subscriptions — cancelled by dispose().
  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  Future<void>? _inFlight;
  bool _isDisposed = false;

  /// Monotonic stamp incremented whenever the socket leaves the connected
  /// state. Each sweep captures the value live at schedule time and aborts
  /// if it later disagrees with [_generation], so a sweep started against
  /// an old socket cannot keep firing `obtain()` after a reconnect lands.
  int _generation = 0;

  void _onConnectionState(ConsumerSocketConnectionState state) {
    if (_isDisposed) {
      return;
    }
    switch (state) {
      case ConsumerSocketConnected():
        if (_inFlight != null) {
          return;
        }
        _scheduleSweep();
      case ConsumerSocketDisconnected():
      case ConsumerSocketError():
      case ConsumerSocketUnauthorized():
        _generation++;
        _inFlight = null;
      case ConsumerSocketConnecting():
        break;
    }
  }

  void _scheduleSweep() {
    final sweepGeneration = _generation;
    final sweep = _runSweep(sweepGeneration);
    _inFlight = sweep;
    unawaited(
      sweep.whenComplete(() {
        if (identical(_inFlight, sweep)) {
          _inFlight = null;
        }
      }),
    );
  }

  Future<void> _runSweep(int sweepGeneration) async {
    final List<String> ids;
    try {
      final loaded = await _loadAgentIds();
      if (_isStale(sweepGeneration)) {
        return;
      }
      ids = loaded.take(_maxAgents).toList(growable: false);
    } on Object catch (error) {
      AppLogger.debug(
        'Relay pre-warm: agent list lookup failed',
        context: <String, Object?>{
          'component': 'RelayConversationPreWarmer',
          'reason': 'load_agent_ids_failed',
          'error': error.toString(),
        },
      );
      return;
    }

    if (_isStale(sweepGeneration) || ids.isEmpty) {
      return;
    }

    AppLogger.debug(
      'Relay pre-warm: opening conversations',
      context: <String, Object?>{
        'component': 'RelayConversationPreWarmer',
        'agentCount': ids.length,
      },
    );

    for (var start = 0; start < ids.length; start += _maxConcurrentStarts) {
      if (_isStale(sweepGeneration)) {
        return;
      }
      final end = start + _maxConcurrentStarts > ids.length
          ? ids.length
          : start + _maxConcurrentStarts;
      await Future.wait<void>(
        ids.sublist(start, end).map((id) => _openSilently(id, sweepGeneration)),
      );
    }
  }

  Future<void> _openSilently(String agentId, int sweepGeneration) async {
    if (_isStale(sweepGeneration)) {
      return;
    }
    try {
      await _conversationManager.obtain(agentId);
    } on Object catch (error) {
      AppLogger.debug(
        'Relay pre-warm: conversation start failed',
        context: <String, Object?>{
          'component': 'RelayConversationPreWarmer',
          'agentId': agentId,
          'error': error.toString(),
        },
      );
    }
  }

  bool _isStale(int sweepGeneration) =>
      _isDisposed || _generation != sweepGeneration;

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    final pendingSub = _stateSub;
    _stateSub = null;
    await pendingSub?.cancel();
    // Any in-flight sweep is orphaned on purpose: the subscription is gone
    // so no new sweeps can start, and the sweep itself swallows errors.
    // Awaiting it here would propagate hangs from an upstream loader (for
    // example, a hub that never replies) into shutdown.
    _inFlight = null;
  }
}
