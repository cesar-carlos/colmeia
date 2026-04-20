import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/application/usecases/observe_agent_presence_use_case.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePresenceStream implements AgentPresenceStream {
  _FakePresenceStream() : _controller = StreamController<AgentPresenceEvent>();

  final StreamController<AgentPresenceEvent> _controller;
  bool disposed = false;

  void emit(AgentPresenceEvent event) => _controller.add(event);

  @override
  Stream<AgentPresenceEvent> events() => _controller.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}

void main() {
  test('forwards the underlying stream untouched', () async {
    final fake = _FakePresenceStream();
    final useCase = ObserveAgentPresenceUseCase(fake);

    final received = <AgentPresenceEvent>[];
    final sub = useCase().listen(received.add);

    final event = AgentPresenceHint(
      agentId: 'a',
      observedAt: DateTime.utc(2026),
      online: true,
      source: 'agents:command_success',
    );
    fake.emit(event);
    await Future<void>.delayed(Duration.zero);

    check(received.length).equals(1);
    check(identical(received.single, event)).isTrue();

    await sub.cancel();
    await fake.dispose();
  });
}
