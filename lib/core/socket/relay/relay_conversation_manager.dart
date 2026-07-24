import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/relay/relay_conversation.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';

/// Tracks one active relay conversation per `agentId`. The dispatcher asks
/// the manager for an active conversation; the manager opens one on demand
/// and recycles it across requests so the hub doesn't need to spin up a new
/// `conversationId` for every RPC.
///
/// Concurrent [obtain] calls for the same `agentId` share a single in-flight
/// Future so the hub never receives two `relay:conversation.start` events
/// for the same agent in the same cold-start wave.
///
/// Resets the registry whenever the underlying socket transitions away from
/// `connected` — relay conversations are bound to the consumer socket id, so
/// any reconnect requires fresh `conversationId`s.
class RelayConversationManager {
  RelayConversationManager({
    required ConsumerSocketConnection connection,
    Duration startTimeout = const Duration(seconds: 10),
    Duration endTimeout = const Duration(seconds: 5),
    SocketChannelMetrics? channelMetrics,
  }) : _connection = connection,
       _startTimeout = startTimeout,
       _endTimeout = endTimeout,
       _channelMetrics = channelMetrics {
    _stateSub = _connection.states().listen(_onConnectionState);
  }

  final ConsumerSocketConnection _connection;
  final Duration _startTimeout;
  final Duration _endTimeout;
  final SocketChannelMetrics? _channelMetrics;

  final Map<String, RelayConversation> _byAgentId =
      <String, RelayConversation>{};

  /// In-flight [obtain] Futures keyed by `agentId`. Concurrent callers share
  /// the same Future so only one conversation is opened per agent.
  final Map<String, Future<RelayConversation>> _inflightObtainByAgentId =
      <String, Future<RelayConversation>>{};

  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  bool _isDisposed = false;

  /// Returns an open conversation for [agentId], opening one on demand.
  /// Concurrent callers for the same [agentId] share a single in-flight
  /// Future (manager-level single-flight); [RelayConversation.start] remains
  /// single-flight as a second line of defense on the instance itself.
  Future<RelayConversation> obtain(String agentId) {
    if (_isDisposed) {
      return Future<RelayConversation>.error(
        StateError('RelayConversationManager used after dispose'),
      );
    }
    final existingActive = _byAgentId[agentId];
    if (existingActive != null && existingActive.isActive) {
      return Future<RelayConversation>.value(existingActive);
    }
    final inflight = _inflightObtainByAgentId[agentId];
    if (inflight != null) {
      return inflight;
    }
    // Share the same Future with concurrent callers. Do not wrap errors in a
    // Completer: `completeError` with no listener yet becomes an unhandled
    // async error and bypasses `_prepareSend`'s typed catches.
    late final Future<RelayConversation> shared;
    shared = _obtainInternal(agentId).whenComplete(() {
      _inflightObtainByAgentId.removeWhere(
        (key, value) => identical(value, shared),
      );
    });
    _inflightObtainByAgentId[agentId] = shared;
    return shared;
  }

  Future<RelayConversation> _obtainInternal(String agentId) async {
    if (_isDisposed) {
      throw StateError('RelayConversationManager used after dispose');
    }
    await _connection.connect();
    if (_isDisposed) {
      throw const RelayConversationStartFailure(
        message: 'RelayConversationManager disposed during obtain',
        code: 'manager_disposed',
      );
    }
    final existing = _byAgentId[agentId];
    if (existing != null && existing.isActive) {
      return existing;
    }
    if (existing != null && !existing.isActive) {
      _byAgentId.remove(agentId);
    }
    final conversation = RelayConversation(
      connection: _connection,
      agentId: agentId,
      startTimeout: _startTimeout,
      endTimeout: _endTimeout,
    );
    _byAgentId[agentId] = conversation;
    // Only the first-time open pays the round-trip; the metric reservoir
    // therefore reflects per-agent cold starts (the pre-warmer is what
    // keeps this off the first SQL wave).
    final startSw = Stopwatch()..start();
    try {
      await conversation.start();
      startSw.stop();
      if (_isDisposed || !_byAgentId.containsKey(agentId)) {
        conversation.forceEnd(reason: 'obtain_superseded');
        throw const RelayConversationStartFailure(
          message: 'Relay conversation was discarded while start was in flight',
          code: 'obtain_superseded',
        );
      }
      _channelMetrics?.recordRelayConversationStart(elapsed: startSw.elapsed);
    } on Object {
      startSw.stop();
      // Don't record failed starts: the latency reservoir is for
      // successful first opens, not for retried/timed-out attempts.
      if (identical(_byAgentId[agentId], conversation)) {
        _byAgentId.remove(agentId);
      }
      rethrow;
    }
    return conversation;
  }

  /// Closes and forgets the conversation tied to [agentId]. Idempotent.
  Future<void> release(String agentId, {String? reason}) async {
    final conversation = _byAgentId.remove(agentId);
    if (conversation == null) {
      return;
    }
    await conversation.end(reason: reason);
  }

  /// Closes every conversation in parallel. Used on logout, transport switch,
  /// dispose. Parallel close avoids blocking for N × endTimeout (default 5s
  /// each) when multiple agents have open conversations.
  Future<void> releaseAll({String? reason}) async {
    final conversations = _byAgentId.values.toList(growable: false);
    _byAgentId.clear();
    await Future.wait(conversations.map((c) => c.end(reason: reason)));
  }

  void _onConnectionState(ConsumerSocketConnectionState state) {
    switch (state) {
      case ConsumerSocketDisconnected():
      case ConsumerSocketError():
      case ConsumerSocketUnauthorized():
        _forceCloseAll(reason: 'socket_dropped');
      case ConsumerSocketConnected():
      case ConsumerSocketConnecting():
        break;
    }
  }

  void _forceCloseAll({required String reason}) {
    if (_byAgentId.isEmpty && _inflightObtainByAgentId.isEmpty) {
      return;
    }
    AppLogger.debug(
      'Discarding active relay conversations',
      context: <String, Object?>{
        'component': 'RelayConversationManager',
        'reason': reason,
        'count': _byAgentId.length,
        'inflightObtainCount': _inflightObtainByAgentId.length,
      },
    );
    final conversations = _byAgentId.values.toList(growable: false);
    _byAgentId.clear();
    for (final conversation in conversations) {
      conversation.forceEnd(reason: reason);
    }
    // In-flight obtain Futures remain until their start settles; they detect
    // discard via `_byAgentId` / disposed checks and fail with
    // `obtain_superseded` or the underlying start failure.
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _stateSub?.cancel();
    _stateSub = null;
    _forceCloseAll(reason: 'manager_disposed');
  }
}
