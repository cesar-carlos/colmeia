import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';

class DisabledAgentPresenceStream implements AgentPresenceStream {
  const DisabledAgentPresenceStream();

  @override
  Stream<AgentPresenceEvent> events() => const Stream.empty();

  @override
  Future<void> dispose() async {}
}
