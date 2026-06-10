import 'package:colmeia/features/client_agents/data/hub_presence_synthesizer.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:flutter_test/flutter_test.dart';

ClientAgentProfileDto _profile(
  String id, {
  bool? isHubConnected,
}) {
  return ClientAgentProfileDto(
    agentId: id,
    name: 'Agent $id',
    status: 'active',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    isHubConnected: isHubConnected,
  );
}

void main() {
  final stamp = DateTime.utc(2026, 4);

  group('synthesizeOnlineAgentsDtoFromProfiles', () {
    test('returns null when no profile carries a hub-presence flag', () {
      final dto = synthesizeOnlineAgentsDtoFromProfiles(
        profiles: <ClientAgentProfileDto>[
          _profile('a'),
          _profile('b'),
        ],
        stamp: stamp,
      );

      expect(dto, isNull);
    });

    test('returns an empty list when every profile is explicitly offline', () {
      final dto = synthesizeOnlineAgentsDtoFromProfiles(
        profiles: <ClientAgentProfileDto>[
          _profile('a', isHubConnected: false),
          _profile('b', isHubConnected: false),
        ],
        stamp: stamp,
      );

      expect(dto, isNotNull);
      expect(dto!.agents, isEmpty);
      expect(dto.count, 0);
    });

    test('only emits profiles with isHubConnected == true', () {
      final dto = synthesizeOnlineAgentsDtoFromProfiles(
        profiles: <ClientAgentProfileDto>[
          _profile('a', isHubConnected: true),
          _profile('b', isHubConnected: false),
          _profile('c', isHubConnected: true),
          _profile('d'),
        ],
        stamp: stamp,
      );

      expect(dto, isNotNull);
      expect(dto!.agents.map((a) => a.agentId), <String>['a', 'c']);
      expect(dto.count, 2);
    });

    test('stamps both connectedAt and lastSeenAt with the same timestamp', () {
      final dto = synthesizeOnlineAgentsDtoFromProfiles(
        profiles: <ClientAgentProfileDto>[
          _profile('a', isHubConnected: true),
        ],
        stamp: stamp,
      );

      expect(dto, isNotNull);
      final entry = dto!.agents.single;
      expect(entry.connectedAt, stamp);
      expect(entry.lastSeenAt, stamp);
    });
  });
}
