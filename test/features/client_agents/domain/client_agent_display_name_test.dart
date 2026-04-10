import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/domain/client_agent_display_name.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveClientAgentDisplayName', () {
    test('should return name when it is non-empty', () {
      final agent = _agent(name: 'Agente Legal', tradeName: 'Fantasia');

      final result = resolveClientAgentDisplayName(agent, 'fallback-id');

      check(result).equals('Agente Legal');
    });

    test('should return trade name when name is blank', () {
      final agent = _agent(name: '   ', tradeName: 'Nome Fantasia');

      final result = resolveClientAgentDisplayName(agent, 'fallback-id');

      check(result).equals('Nome Fantasia');
    });

    test('should return fallback agent id when names are absent', () {
      final agent = _agent(name: ' ', tradeName: ' ');

      final result = resolveClientAgentDisplayName(agent, 'agent-123');

      check(result).equals('agent-123');
    });

    test('should return fallback agent id when agent is null', () {
      final result = resolveClientAgentDisplayName(null, 'agent-123');

      check(result).equals('agent-123');
    });
  });
}

ClientAgent _agent({
  required String name,
  required String? tradeName,
}) {
  return ClientAgent(
    agentId: 'agent-1',
    name: name,
    tradeName: tradeName,
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
}
