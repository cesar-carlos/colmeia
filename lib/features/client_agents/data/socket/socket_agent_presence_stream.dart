import 'dart:async';

import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/features/client_agents/data/socket/agent_command_presence_hinter.dart';
import 'package:colmeia/features/client_agents/data/socket/client_agent_profile_updated_listener.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';

/// Socket implementation of [AgentPresenceStream] that combines:
///
/// - **Camada 1** — `ClientAgentProfileUpdatedListener`
///   (`client:agent.profile.updated` PayloadFrame events).
/// - **Camada 2** — `AgentCommandPresenceHinter` (hints derived from
///   `agents:command` outcomes).
///
/// Both feed the same internal broadcast `StreamController`, exposed as
/// [sink] so the listener and hinter can be constructed *after* the
/// stream (avoids the circular reference of "stream needs listener,
/// listener needs sink"). Use [bind] once both adapters are built —
/// typically inside the DI module that wires presence.
///
/// Re-attach is automatic on socket reconnect: the stream observes
/// [ConsumerSocketConnection.states] and re-runs `attach()` on every
/// transition into [ConsumerSocketConnected]. This keeps the listener
/// alive across `pause()`/`resume()` and after auth refresh.
class SocketAgentPresenceStream implements AgentPresenceStream {
  /// Two-step construction (preferred for DI):
  ///
  /// ```dart
  /// final stream = SocketAgentPresenceStream.deferred(connection: c);
  /// final listener = ClientAgentProfileUpdatedListener(
  ///   connection: c, sink: stream.sink, /* ... */);
  /// final hinter = AgentCommandPresenceHinter(
  ///   dispatcher: d, sink: stream.sink);
  /// stream.bind(catalogListener: listener, commandHinter: hinter);
  /// ```
  SocketAgentPresenceStream.deferred({
    required this._connection,
  }) : _controller = StreamController<AgentPresenceEvent>.broadcast() {
    _stateSub = _connection.states().listen(_onConnectionState);
  }

  /// Single-step construction used by tests that already have all the
  /// adapters in scope.
  factory SocketAgentPresenceStream.bound({
    required ConsumerSocketConnection connection,
    required ClientAgentProfileUpdatedListener catalogListener,
    required AgentCommandPresenceHinter commandHinter,
  }) {
    return SocketAgentPresenceStream.deferred(connection: connection)..bind(
      catalogListener: catalogListener,
      commandHinter: commandHinter,
    );
  }

  final ConsumerSocketConnection _connection;
  final StreamController<AgentPresenceEvent> _controller;

  ClientAgentProfileUpdatedListener? _catalogListener;
  AgentCommandPresenceHinter? _commandHinter;
  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  bool _isDisposed = false;

  /// Output sink shared by the catalog listener, the command hinter and
  /// any future presence sources. Always points at the broadcast
  /// controller backing [events].
  Sink<AgentPresenceEvent> get sink => _controller.sink;

  /// Wires the inbound adapters into the stream. Idempotent: a second
  /// call replaces the previous adapters (after disposing them) so the
  /// caller can swap implementations in tests without rebuilding the
  /// stream itself.
  void bind({
    required ClientAgentProfileUpdatedListener catalogListener,
    required AgentCommandPresenceHinter commandHinter,
  }) {
    if (_isDisposed) {
      return;
    }
    final previousListener = _catalogListener;
    final previousHinter = _commandHinter;
    _catalogListener = catalogListener;
    _commandHinter = commandHinter;

    if (previousListener != null &&
        !identical(previousListener, catalogListener)) {
      // Replacing the bind: detach the previous listener in the
      // background — `dispose()` returns Future<void> that we do not
      // need to await because the new listener takes over immediately.
      // ignore: discarded_futures
      previousListener.dispose();
    }
    if (previousHinter != null && !identical(previousHinter, commandHinter)) {
      // Same rationale as above for the hinter subscription.
      // ignore: discarded_futures
      previousHinter.dispose();
    }

    // The hinter only needs the dispatcher outcome stream, not the
    // socket itself, so we can attach immediately. The listener needs
    // a live raw socket; if we already are connected, attach now;
    // otherwise wait for the next ConsumerSocketConnected transition.
    commandHinter.attach();
    if (_connection.isConnected) {
      catalogListener.attach();
    }
  }

  @override
  Stream<AgentPresenceEvent> events() => _controller.stream;

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _stateSub?.cancel();
    _stateSub = null;
    await _catalogListener?.dispose();
    _catalogListener = null;
    await _commandHinter?.dispose();
    _commandHinter = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void _onConnectionState(ConsumerSocketConnectionState state) {
    final listener = _catalogListener;
    if (listener == null) {
      return;
    }
    switch (state) {
      case ConsumerSocketConnected():
        listener.attach();
      case ConsumerSocketDisconnected():
      case ConsumerSocketError():
      case ConsumerSocketUnauthorized():
        // Detach so the next connect re-installs a fresh handler on
        // the new io.Socket instance. The hinter stays attached
        // because it observes the in-memory dispatcher stream, not
        // the raw socket.
        // ignore: discarded_futures
        listener.dispose();
      case ConsumerSocketConnecting():
        break;
    }
  }
}
