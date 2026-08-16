import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
import 'package:colmeia/core/socket/socket_wire_utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef ConversationEndedCallback = void Function({
  required String conversationId,
  String? requestId,
  String? reason,
});

/// Routes hub-initiated `relay:conversation.ended` events to all registered
/// listeners through a single permanent raw-socket handler.
///
/// Both `RelayConversationManager` and `RelayCommandDispatcherImpl` subscribe
/// so each can react to hub-side conversation termination (expired,
/// agent_disconnected) without owning their own raw-socket listener.
///
/// Uses the same socket-identity-check pattern as
/// `RelayCommandDispatcherImpl`: the handler is detached when the socket
/// tears down and re-attached when [ConsumerSocketConnected] is observed.
class RelayConversationEndedRouter {
  RelayConversationEndedRouter({
    required this._connection,
  }) {
    _stateSub = _connection.states().listen(_onConnectionState);
    // Attach immediately if the socket is already up at construction time,
    // which happens when the router is resolved lazily after first connect.
    if (_connection.isConnected) {
      _attach();
    }
  }

  final ConsumerSocketConnection _connection;
  final List<ConversationEndedCallback> _listeners = [];

  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  io.Socket? _attachedSocket;
  bool _isDisposed = false;

  void addListener(ConversationEndedCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(ConversationEndedCallback listener) {
    _listeners.remove(listener);
  }

  void _attach() {
    final socket = _connection.raw;
    if (identical(_attachedSocket, socket)) {
      return;
    }
    _detach();
    socket.on(RelayEventNames.conversationEnded, _onConversationEnded);
    _attachedSocket = socket;
    AppLogger.debug(
      'RelayConversationEndedRouter attached',
      context: <String, Object?>{
        'component': 'RelayConversationEndedRouter',
        'socketIdentity': identityHashCode(socket),
      },
    );
  }

  void _detach() {
    final socket = _attachedSocket;
    if (socket == null) {
      return;
    }
    try {
      socket.off(RelayEventNames.conversationEnded, _onConversationEnded);
    } on Object catch (_) {
      // Socket already being torn down; the next connect will re-attach.
    }
    _attachedSocket = null;
  }

  void _onConversationEnded(Object? raw) {
    final map = socketToStringKeyedMap(raw);
    if (map == null) {
      return;
    }
    final conversationId = map['conversationId']?.toString();
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }
    final rawRequestId = map['requestId']?.toString();
    final rawReason = map['reason']?.toString();
    final requestId = (rawRequestId?.isEmpty ?? true) ? null : rawRequestId;
    final reason = (rawReason?.isEmpty ?? true) ? null : rawReason;

    for (final listener in List<ConversationEndedCallback>.of(_listeners)) {
      listener(
        conversationId: conversationId,
        requestId: requestId,
        reason: reason,
      );
    }
  }

  void _onConnectionState(ConsumerSocketConnectionState state) {
    switch (state) {
      case ConsumerSocketConnected():
        _attach();
      case ConsumerSocketDisconnected():
      case ConsumerSocketError():
      case ConsumerSocketUnauthorized():
        _detach();
      case ConsumerSocketConnecting():
        break;
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _stateSub?.cancel();
    _stateSub = null;
    _detach();
    _listeners.clear();
  }
}
