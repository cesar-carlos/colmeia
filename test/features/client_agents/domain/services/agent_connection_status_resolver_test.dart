import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/services/agent_connection_status_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAgentConnectionStatus', () {
    test('hub true forces online', () {
      expect(
        resolveAgentConnectionStatus(
          agentId: 'a1',
          isHubConnected: true,
          onlineAgentIds: null,
        ),
        AgentConnectionStatus.online,
      );
    });

    test('hub false forces offline regardless of online set', () {
      expect(
        resolveAgentConnectionStatus(
          agentId: 'a1',
          isHubConnected: false,
          onlineAgentIds: {'a1'},
        ),
        AgentConnectionStatus.offline,
      );
    });

    test('hub null and onlineIds null yields unknown', () {
      expect(
        resolveAgentConnectionStatus(
          agentId: 'a1',
          isHubConnected: null,
          onlineAgentIds: null,
        ),
        AgentConnectionStatus.unknown,
      );
    });

    test('hub null and id in set yields online', () {
      expect(
        resolveAgentConnectionStatus(
          agentId: 'a1',
          isHubConnected: null,
          onlineAgentIds: {'a1', 'a2'},
        ),
        AgentConnectionStatus.online,
      );
    });

    test('hub null and id not in set yields offline', () {
      expect(
        resolveAgentConnectionStatus(
          agentId: 'a1',
          isHubConnected: null,
          onlineAgentIds: {'a2'},
        ),
        AgentConnectionStatus.offline,
      );
    });

    test('empty online set yields offline when hub null', () {
      expect(
        resolveAgentConnectionStatus(
          agentId: 'a1',
          isHubConnected: null,
          onlineAgentIds: <String>{},
        ),
        AgentConnectionStatus.offline,
      );
    });
  });
}
