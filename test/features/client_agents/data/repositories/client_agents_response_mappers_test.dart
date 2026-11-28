import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_response_mappers.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final connected in [true, false]) {
    final json = <String, dynamic>{
      'agentId': 'agent-a',
      'name': 'Branch',
      'status': 'active',
      'isHubConnected': connected,
    };

    test('stale profile does not assert presence ($connected)', () {
      final profile = ClientAgentProfileDto.fromJson(json);
      final stale = mapClientAgentProfile(
        profile,
        onlineIds: {'agent-a'},
        isStaleCache: true,
      );
      expect(stale.isStaleCache, isTrue);
      expect(stale.connectionStatus, AgentConnectionStatus.unknown);
      final fresh = mapClientAgentProfile(profile, onlineIds: null);
      expect(
        fresh.connectionStatus,
        connected
            ? AgentConnectionStatus.online
            : AgentConnectionStatus.offline,
      );
    });

    test('approved list propagates stale state ($connected)', () {
      final page = mapClientApprovedAgentsResponse(
        ClientApprovedAgentsResponseDto.fromJson({
          'agents': [json],
        }),
        onlineIds: {},
        isStaleCache: true,
      );
      expect(page.isStaleCache, isTrue);
      expect(page.items.single.isStaleCache, isTrue);
      expect(page.items.single.connectionStatus, AgentConnectionStatus.unknown);
    });

    test('catalog propagates stale state to item and profile ($connected)', () {
      final page = mapClientAgentCatalogResponse(
        PaginatedAgentCatalogResponseDto.fromJson({
          'agents': [json],
        }),
        onlineIds: {},
        isStaleCache: true,
      );
      expect(page.isStaleCache, isTrue);
      expect(page.items.single.isStaleCache, isTrue);
      expect(page.items.single.agent.isStaleCache, isTrue);
      expect(
        page.items.single.agent.connectionStatus,
        AgentConnectionStatus.unknown,
      );
    });
  }
}
