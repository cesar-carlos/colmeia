import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_meta/data/models/agent_get_profile_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentGetProfileResponseDto.fromResult', () {
    test('parses snake_case fields and integer profile_version', () {
      final dto = AgentGetProfileResponseDto.fromResult(<String, Object?>{
        'agent_id': '11111111-1111-1111-8111-111111111111',
        'name': 'Plug Norte',
        'profile_version': 17,
        'trade_name': 'Norte BI',
        'document': '12345678901',
        'document_type': 'cpf',
        'profile_updated_at': '2026-04-15T12:30:00.000Z',
      });
      check(dto.agentId).equals('11111111-1111-1111-8111-111111111111');
      check(dto.name).equals('Plug Norte');
      check(dto.profileVersion).equals(17);
      check(dto.tradeName).equals('Norte BI');
      check(dto.documentType).equals('cpf');
      check(dto.profileUpdatedAt).isNotNull();
    });

    test('accepts camelCase aliases (agentId / profileVersion)', () {
      final dto = AgentGetProfileResponseDto.fromResult(<String, Object?>{
        'agentId': 'a',
        'name': 'x',
        'profileVersion': 5,
      });
      check(dto.agentId).equals('a');
      check(dto.profileVersion).equals(5);
    });

    test('returns null profileVersion when absent or non-numeric', () {
      final dto = AgentGetProfileResponseDto.fromResult(<String, Object?>{
        'agent_id': 'a',
        'name': 'x',
      });
      check(dto.profileVersion).isNull();

      final dto2 = AgentGetProfileResponseDto.fromResult(<String, Object?>{
        'agent_id': 'a',
        'name': 'x',
        'profile_version': 'abc',
      });
      check(dto2.profileVersion).isNull();
    });

    test('preserves the raw payload for diagnostics', () {
      final dto = AgentGetProfileResponseDto.fromResult(<String, Object?>{
        'agent_id': 'a',
        'name': 'x',
        'unknown_future_field': 42,
      });
      check(dto.raw['unknown_future_field']).equals(42);
    });

    test('toEntity carries profileVersion through to the snapshot', () {
      final dto = AgentGetProfileResponseDto.fromResult(<String, Object?>{
        'agent_id': 'a',
        'name': 'x',
        'profile_version': 9,
      });
      final entity = dto.toEntity();
      check(entity.agentId).equals('a');
      check(entity.profileVersion).equals(9);
    });
  });
}
