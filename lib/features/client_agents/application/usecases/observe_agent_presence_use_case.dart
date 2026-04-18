import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';

/// Single entry point used by presentation to subscribe to presence
/// events. Does NOT fan-out by `agentId`: the controller filters/dedupes
/// (see design §6.4). Keeping the surface minimal avoids tying the UI to
/// a particular subscription topology.
class ObserveAgentPresenceUseCase {
  const ObserveAgentPresenceUseCase(this._stream);

  final AgentPresenceStream _stream;

  Stream<AgentPresenceEvent> call() => _stream.events();
}
