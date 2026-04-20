import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientAgentTokenResponseDto.fromJson', () {
    test('parses agentId and clientToken', () {
      final dto = ClientAgentTokenResponseDto.fromJson(
        <String, dynamic>{
          'agentId': '11111111-1111-1111-8111-111111111111',
          'clientToken': 'secret',
        },
      );
      check(dto.agentId).equals('11111111-1111-1111-8111-111111111111');
      check(dto.clientToken).equals('secret');
      check(dto.hasClientToken).isTrue();
    });

    test('treats null clientToken as no token stored', () {
      final dto = ClientAgentTokenResponseDto.fromJson(
        const <String, dynamic>{
          'agentId': 'a',
          'clientToken': null,
        },
      );
      check(dto.clientToken).isNull();
      check(dto.hasClientToken).isFalse();
    });

    test('treats whitespace-only clientToken as no token stored', () {
      final dto = ClientAgentTokenResponseDto.fromJson(
        const <String, dynamic>{
          'agentId': 'a',
          'clientToken': '   ',
        },
      );
      check(dto.hasClientToken).isFalse();
    });

    test('falls back to empty agentId when missing', () {
      final dto = ClientAgentTokenResponseDto.fromJson(
        const <String, dynamic>{'clientToken': 'x'},
      );
      check(dto.agentId).equals('');
      check(dto.hasClientToken).isTrue();
    });
  });

  test('toJson keeps explicit null token to mirror server contract', () {
    const dto = ClientAgentTokenResponseDto(
      agentId: 'a',
      clientToken: null,
    );
    check(dto.toJson()).deepEquals(<String, Object?>{
      'agentId': 'a',
      'clientToken': null,
    });
  });
}
