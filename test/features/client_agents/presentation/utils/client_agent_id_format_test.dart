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
}
