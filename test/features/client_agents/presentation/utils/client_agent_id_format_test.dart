import 'package:colmeia/features/client_agents/presentation/utils/client_agent_id_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAgentIdsFromFreeformDraft preserves order and dedupes', () {
    final ids = parseAgentIdsFromFreeformDraft('''
11111111-1111-1111-8111-111111111111,
22222222-2222-2222-8222-222222222222
11111111-1111-1111-8111-111111111111
bad
''');
    expect(ids, <String>[
      '11111111-1111-1111-8111-111111111111',
      '22222222-2222-2222-8222-222222222222',
    ]);
  });

  group('isValidClientAgentId', () {
    test('accepts UUIDv4 (legacy hubs)', () {
      expect(
        isValidClientAgentId('6ac362c2-72b5-4f2f-a071-96fe6f5f5080'),
        isTrue,
      );
    });

    test('accepts UUIDv7 (modern hubs)', () {
      // v7 has the version slot starting with `7`.
      expect(
        isValidClientAgentId('018f0c4a-7b3d-7000-8000-000000000001'),
        isTrue,
      );
    });

    test('accepts UUIDv8 (custom variants)', () {
      expect(
        isValidClientAgentId('11111111-1111-8111-8111-111111111111'),
        isTrue,
      );
    });

    test('rejects nil UUID (version slot 0)', () {
      expect(
        isValidClientAgentId('00000000-0000-0000-0000-000000000000'),
        isFalse,
      );
    });

    test('rejects malformed UUID (length / hyphens)', () {
      expect(isValidClientAgentId('not-a-uuid'), isFalse);
      expect(
        isValidClientAgentId('11111111-1111-1111-1111-1111'),
        isFalse,
      );
    });

    test('rejects bad variant bits (variant slot must start with 8/9/a/b)', () {
      expect(
        isValidClientAgentId('11111111-1111-4111-1111-111111111111'),
        isFalse,
      );
    });
  });
}
