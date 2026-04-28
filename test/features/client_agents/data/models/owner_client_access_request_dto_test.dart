import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/data/models/owner_client_access_request_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps nested owner access request payloads', () {
    final dto = OwnerClientAccessRequestDto.fromJson(<String, dynamic>{
      'id': 'rq-900',
      'status': 'pending',
      'createdAt': '2026-04-28T10:00:00.000Z',
      'agent': <String, dynamic>{
        'id': 'agent-1',
        'name': 'Plug Norte',
      },
      'client': <String, dynamic>{
        'id': 'client-1',
        'name': 'Casa do Mel',
        'email': 'contato@casadomel.test',
      },
    });

    final entity = dto.toEntity();

    check(entity.requestId).equals('rq-900');
    check(entity.agentId).equals('agent-1');
    check(entity.agentName).equals('Plug Norte');
    check(entity.clientId).equals('client-1');
    check(entity.clientName).equals('Casa do Mel');
    check(entity.clientEmail).equals('contato@casadomel.test');
    check(entity.status).equals(AgentAccessRequestStatus.pending);
    check(entity.requestedAt).isNotNull();
  });
}
