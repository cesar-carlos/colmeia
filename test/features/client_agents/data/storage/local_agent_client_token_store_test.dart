import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockFlutterSecureStorage secure;
  late LocalAgentClientTokenStore store;

  setUp(() {
    secure = _MockFlutterSecureStorage();
    store = LocalAgentClientTokenStore(secure);
  });

  test('write trims token and uses scoped storage key', () async {
    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    await store.write(
      userId: ' user-1 ',
      agentId: ' 11111111-1111-1111-8111-111111111111 ',
      clientToken: '  abc  ',
    );

    verify(
      () => secure.write(
        key:
            'colmeia.agent_client_token.v1|user-1|'
            '11111111-1111-1111-8111-111111111111',
        value: 'abc',
      ),
    ).called(1);
  });

  test('write with blank token deletes storage entry', () async {
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await store.write(
      userId: 'u',
      agentId: '11111111-1111-1111-8111-111111111111',
      clientToken: '   ',
    );

    verify(
      () => secure.delete(
        key:
            'colmeia.agent_client_token.v1|u|'
            '11111111-1111-1111-8111-111111111111',
      ),
    ).called(1);
    verifyNever(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('readMany returns only agents with non-empty tokens', () async {
    when(
      () => secure.read(
        key:
            'colmeia.agent_client_token.v1|u|'
            '11111111-1111-1111-8111-111111111111',
      ),
    ).thenAnswer((_) async => 'one');
    when(
      () => secure.read(
        key:
            'colmeia.agent_client_token.v1|u|'
            '22222222-2222-2222-8222-222222222222',
      ),
    ).thenAnswer((_) async => '  ');
    when(
      () => secure.read(
        key:
            'colmeia.agent_client_token.v1|u|'
            '33333333-3333-3333-8333-333333333333',
      ),
    ).thenAnswer((_) async => null);

    final map = await store.readMany(
      userId: 'u',
      agentIds: <String>[
        '11111111-1111-1111-8111-111111111111',
        '22222222-2222-2222-8222-222222222222',
        '33333333-3333-3333-8333-333333333333',
      ],
    );

    expect(map.length, 1);
    expect(
      map['11111111-1111-1111-8111-111111111111'],
      'one',
    );
  });

  test('read returns null when secure storage throws unexpectedly', () async {
    when(() => secure.read(key: any(named: 'key'))).thenThrow(
      Exception('storage error'),
    );

    final v = await store.read(
      userId: 'u',
      agentId: '11111111-1111-1111-8111-111111111111',
    );
    expect(v, isNull);
  });

  test('readMany deduplicates ids and reads in parallel', () async {
    const id = '11111111-1111-1111-8111-111111111111';
    when(() => secure.read(key: any(named: 'key'))).thenAnswer(
      (_) async => 'tok',
    );

    final map = await store.readMany(
      userId: 'u',
      agentIds: <String>[id, ' $id ', id],
    );

    expect(map.length, 1);
    expect(map[id], 'tok');
    verify(() => secure.read(key: any(named: 'key'))).called(1);
  });
}
