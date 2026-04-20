import 'dart:async';

import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';

/// Subscribes to `SocketCommandDispatcher.outcomes()` and turns each
/// outcome into an `AgentPresenceHint` (Camada 2 do plano §19).
///
/// Mapping rules (aligned with the design):
///
/// | Outcome                         | Hint                |
/// | ------------------------------- | ------------------- |
/// | `AgentCommandSuccess`           | `online: true`      |
/// | `AgentCommandFailedOffline`     | `online: false`     |
/// | `AgentCommandFailedAuth`        | (no hint — auth says nothing about presence) |
/// | `AgentCommandFailedTransient`   | (no hint — could be timeout/decode/rate; ambiguous) |
///
/// Lifecycle: `attach()` is idempotent; `dispose()` cancels the
/// subscription. Both are safe to call out of order.
class AgentCommandPresenceHinter {
  AgentCommandPresenceHinter({
    required SocketCommandDispatcher dispatcher,
    required Sink<AgentPresenceEvent> sink,
  }) : _dispatcher = dispatcher,
       _sink = sink;

  final SocketCommandDispatcher _dispatcher;
  final Sink<AgentPresenceEvent> _sink;

  // Cancelled in `dispose()`; the lint cannot see across the indirection.
  // ignore: cancel_subscriptions
  StreamSubscription<AgentCommandOutcome>? _sub;

  bool get isAttached => _sub != null;

  void attach() {
    _sub ??= _dispatcher.outcomes().listen(_onOutcome);
  }

  Future<void> dispose() async {
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
  }

  void _onOutcome(AgentCommandOutcome outcome) {
    switch (outcome) {
      case AgentCommandSuccess():
        _sink.add(
          AgentPresenceHint(
            agentId: outcome.agentId,
            observedAt: outcome.observedAt,
            online: true,
            source: 'agents:command_success',
          ),
        );
      case AgentCommandFailedOffline():
        _sink.add(
          AgentPresenceHint(
            agentId: outcome.agentId,
            observedAt: outcome.observedAt,
            online: false,
            source: 'agents:command_error_offline',
          ),
        );
      case AgentCommandFailedAuth():
      case AgentCommandFailedTransient():
        // Auth and transient failures do not interpret presence:
        // - Auth (`-32001`/`-32002`, `AGENT_ACCESS_DENIED`) means the
        //   call was rejected before the agent was reached.
        // - Transient (timeout, decode_failed, rate limit) does not
        //   distinguish between "agent down" and "network blip".
        return;
    }
  }
}
