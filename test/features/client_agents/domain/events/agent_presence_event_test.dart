import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final observedAt = DateTime.utc(2026, 4, 17, 12);

  group('AgentPresenceCatalogUpdated', () {
    test('keeps changedFields and profileVersion verbatim', () {
      final event = AgentPresenceCatalogUpdated(
        agentId: 'agent-1',
        observedAt: observedAt,
        changedFields: const <String>{'phone', 'address'},
        profileVersion: 7,
        source: 'http',
      );
      check(event.agentId).equals('agent-1');
      check(event.observedAt).equals(observedAt);
      check(event.changedFields).deepEquals(const <String>{'phone', 'address'});
      check(event.profileVersion).equals(7);
      check(event.source).equals('http');
    });

    test('changedFields defaults to an empty set', () {
      final event = AgentPresenceCatalogUpdated(
        agentId: 'agent-1',
        observedAt: observedAt,
      );
      check(event.changedFields).isEmpty();
      check(event.profileVersion).isNull();
      check(event.source).isNull();
    });
  });

  group('AgentPresenceHint', () {
    test('connectionStatusFromHint maps online/offline to enum', () {
      final online = AgentPresenceHint(
        agentId: 'a',
        observedAt: observedAt,
        online: true,
        source: 'agents:command_success',
      );
      final offline = AgentPresenceHint(
        agentId: 'a',
        observedAt: observedAt,
        online: false,
        source: 'agents:command_error_offline',
      );
      check(
        connectionStatusFromHint(online),
      ).equals(AgentConnectionStatus.online);
      check(
        connectionStatusFromHint(offline),
      ).equals(AgentConnectionStatus.offline);
    });
  });

  group('exhaustive switch', () {
    test('AgentPresenceEvent sealed enumerates exactly two cases', () {
      AgentPresenceEvent event = AgentPresenceCatalogUpdated(
        agentId: 'a',
        observedAt: observedAt,
      );
      var hits = 0;
      void run(AgentPresenceEvent e) {
        switch (e) {
          case AgentPresenceCatalogUpdated():
            hits += 1;
          case AgentPresenceHint():
            hits += 10;
        }
      }

      run(event);
      event = AgentPresenceHint(
        agentId: 'a',
        observedAt: observedAt,
        online: true,
        source: 'agents:command_success',
      );
      run(event);
      check(hits).equals(11);
    });
  });
}
