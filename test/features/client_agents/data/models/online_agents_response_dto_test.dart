import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson skips malformed agent rows but keeps valid ids', () {
    final dto = OnlineAgentsResponseDto.fromJson(<String, dynamic>{
      'agents': <dynamic>[
        <String, dynamic>{
          'agentId': '11111111-1111-1111-1111-111111111111',
          'connectedAt': '2024-01-01T00:00:00.000',
        },
        <String, dynamic>{'invalid': true},
        <String, dynamic>{
          'id': '22222222-2222-2222-2222-222222222222',
          'lastSeenAt': '2024-01-02T00:00:00.000',
        },
      ],
      'count': 99,
    });

    expect(dto.agents.length, 2);
    expect(dto.agents[0].agentId, '11111111-1111-1111-1111-111111111111');
    expect(dto.agents[1].agentId, '22222222-2222-2222-2222-222222222222');
    expect(dto.count, 99);
    expect(dto.malformedAgentRowCount, 1);
  });

  test('fromJson counts non-object rows as malformed', () {
    final dto = OnlineAgentsResponseDto.fromJson(<String, dynamic>{
      'agents': <dynamic>[
        'not-an-object',
        <String, dynamic>{
          'agentId': '33333333-3333-3333-3333-333333333333',
        },
      ],
    });
    expect(dto.agents.length, 1);
    expect(dto.malformedAgentRowCount, 1);
  });

  test('fromJson accepts typical GET /agents hub payload shape', () {
    final dto = OnlineAgentsResponseDto.fromJson(<String, dynamic>{
      'agents': <dynamic>[
        <String, dynamic>{
          'agentId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'connectedAt': '2026-04-01T12:00:00.000Z',
          'lastSeenAt': '2026-04-01T12:05:00.000Z',
        },
      ],
      'count': 1,
    });
    expect(dto.agents.length, 1);
    expect(dto.agents.single.agentId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
    expect(dto.count, 1);
    expect(dto.malformedAgentRowCount, 0);
  });

  test('fromJson yields empty agents when list is empty', () {
    final dto = OnlineAgentsResponseDto.fromJson(<String, dynamic>{
      'agents': <dynamic>[],
    });
    expect(dto.agents, isEmpty);
    expect(dto.count, 0);
    expect(dto.malformedAgentRowCount, 0);
  });
}
