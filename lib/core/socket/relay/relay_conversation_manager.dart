import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/relay/relay_conversation.dart';

/// Tracks one active relay conversation per `agentId`. The dispatcher asks
/// the manager for an active conversation; the manager opens one on demand
/// and recycles it across requests so the hub doesn't need to spin up a new
/// `conversationId` for every RPC.
///
/// Resets the registry whenever the underlying socket transitions away from
/// `connected` — relay conversations are bound to the consumer socket id, so
/// any reconnect requires fresh `conversationId`s.
class RelayConversationManager {
  RelayConversationManager({
    required ConsumerSocketConnection connection,
    Duration startTimeout = const Duration(seconds: 10),
    Duration endTimeout = const Duration(seconds: 5),
  }) : _connection = connection,
       _startTimeout = startTimeout,
       _endTimeout = endTimeout {
    _stateSub = _connection.states().listen(_onConnectionState);
  }

  final ConsumerSocketConnection _connection;
  final Duration _startTimeout;
  final Duration _endTimeout;

  final Map<String, RelayConversation> _byAgentId =
      <String, RelayConversation>{};

  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  bool _isDisposed = false;

  /// Returns an open conversation for [agentId], opening one on demand. A
  /// single in-flight start is shared by concurrent callers via
  /// [RelayConversation.start].
  Future<RelayConversation> obtain(String agentId) async {
    if (_isDisposed) {
      throw StateError('RelayConversationManager used after dispose');
    }
    await _connection.connect();
    final existing = _byAgentId[agentId];
    if (existing != null && existing.isActive) {
      return existing;
    }
    final conversation =
        existing ??
        RelayConversation(
          connection: _connection,
          agentId: agentId,
          startTimeout: _startTimeout,
          endTimeout: _endTimeout,
        );
    _byAgentId[agentId] = conversation;
    await conversation.start();
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
    if (_byAgentId.isEmpty) {
      return;
    }
    AppLogger.debug(
      'Discarding active relay conversations',
      context: <String, Object?>{
        'component': 'RelayConversationManager',
        'reason': reason,
        'count': _byAgentId.length,
      },
    );
    final conversations = _byAgentId.values.toList(growable: false);
    _byAgentId.clear();
    for (final conversation in conversations) {
      conversation.forceEnd(reason: reason);
    }
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
