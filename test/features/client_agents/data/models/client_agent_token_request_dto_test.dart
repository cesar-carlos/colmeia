import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_request_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientAgentTokenRequestDto.normalized', () {
    test('trims input and keeps non-empty value', () {
      const dto = ClientAgentTokenRequestDto(clientToken: '  abc  ');
      check(dto.normalized).equals('abc');
    });

    test('returns null for whitespace-only token', () {
      const dto = ClientAgentTokenRequestDto(clientToken: '   ');
      check(dto.normalized).isNull();
    });

    test('returns null when input is null', () {
      const dto = ClientAgentTokenRequestDto(clientToken: null);
      check(dto.normalized).isNull();
    });
  });

  group('ClientAgentTokenRequestDto.validationError', () {
    test('returns null for token within length cap', () {
      const dto = ClientAgentTokenRequestDto(clientToken: 'short');
      check(dto.validationError()).isNull();
    });

    test('returns null when token is null (clear request)', () {
      const dto = ClientAgentTokenRequestDto(clientToken: null);
      check(dto.validationError()).isNull();
    });

    test('rejects token longer than maxTokenLength after trim', () {
      final long = 'a' * (ClientAgentTokenRequestDto.maxTokenLength + 1);
      final dto = ClientAgentTokenRequestDto(clientToken: long);
      check(dto.validationError()).isNotNull();
    });

    test('accepts token exactly at maxTokenLength', () {
      final atCap = 'a' * ClientAgentTokenRequestDto.maxTokenLength;
      final dto = ClientAgentTokenRequestDto(clientToken: atCap);
      check(dto.validationError()).isNull();
    });
  });

  test('toJson serializes normalized value (null clears the token)', () {
    const dto = ClientAgentTokenRequestDto(clientToken: '   ');
    check(dto.toJson()).deepEquals(<String, Object?>{'clientToken': null});

    const filled = ClientAgentTokenRequestDto(clientToken: ' x ');
    check(filled.toJson()).deepEquals(<String, Object?>{'clientToken': 'x'});
  });
}
