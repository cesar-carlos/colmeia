import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_response_dto.dart';
import 'package:colmeia/features/client_agents/data/repositories/remote_agent_client_token_repository.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClientAgentsRemoteDataSource extends Mock
    implements ClientAgentsRemoteDataSource {}

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

String _storedTokenEnvelope(
  String token, {
  required DateTime savedAt,
}) {
  return jsonEncode(<String, Object?>{
    'token': token,
    'savedAt': savedAt.toUtc().toIso8601String(),
  });
}

void main() {
  late _MockClientAgentsRemoteDataSource remote;
  late _MockFlutterSecureStorage secure;
  late LocalAgentClientTokenStore localStore;
  late RemoteAgentClientTokenRepository repository;

  const userId = 'user-1';
  const agentId = '11111111-1111-1111-8111-111111111111';

  setUpAll(() {
    registerFallbackValue(
      const ClientAgentTokenRequestDto(clientToken: null),
    );
  });

  setUp(() {
    remote = _MockClientAgentsRemoteDataSource();
    secure = _MockFlutterSecureStorage();
    localStore = LocalAgentClientTokenStore(secure);
    repository = RemoteAgentClientTokenRepository(
      remoteDataSource: remote,
      localStore: localStore,
    );

    when(
      () => secure.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(
      () => secure.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
  });

  group('getToken', () {
    test('returns server token and writes to local cache', () async {
      when(
        () => remote.fetchClientAgentToken(agentId: any(named: 'agentId')),
      ).thenAnswer(
        (_) async => const ClientAgentTokenResponseDto(
          agentId: agentId,
          clientToken: 'tok',
        ),
      );

      final result = await repository.getToken(
        userId: userId,
        agentId: agentId,
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.token).equals('tok');
      final captured =
          verify(
                () => secure.write(
                  key: any(named: 'key', that: contains(agentId)),
                  value: captureAny(named: 'value'),
                ),
              ).captured.single
              as String;
      check(captured.contains('"token":"tok"')).isTrue();
      check(captured.contains('"savedAt":"')).isTrue();
    });

    test('clears local cache when server returns null token', () async {
      when(
        () => remote.fetchClientAgentToken(agentId: any(named: 'agentId')),
      ).thenAnswer(
        (_) async => const ClientAgentTokenResponseDto(
          agentId: agentId,
          clientToken: null,
        ),
      );

      final result = await repository.getToken(
        userId: userId,
        agentId: agentId,
      );

      check(result.getOrNull()?.token).isNull();
      check(result.getOrNull()?.hasToken).equals(false);
      verify(
        () => secure.delete(
          key: any(named: 'key', that: contains(agentId)),
        ),
      ).called(1);
    });

    test(
      'returns AuthorizationFailure on 403 (no fallback to cache)',
      () async {
        when(
          () => remote.fetchClientAgentToken(agentId: any(named: 'agentId')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            response: Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: 403,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repository.getToken(
          userId: userId,
          agentId: agentId,
        );

        check(result.exceptionOrNull()).isA<AuthorizationFailure>();
        verifyNever(() => secure.read(key: any(named: 'key')));
      },
    );

    test('falls back to local cache on transient network failure', () async {
      when(
        () => remote.fetchClientAgentToken(agentId: any(named: 'agentId')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      when(
        () => secure.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'cached-tok');

      final result = await repository.getToken(
        userId: userId,
        agentId: agentId,
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.token).equals('cached-tok');
    });

    test(
      'returns NetworkFailure when network fails and cache is empty',
      () async {
        when(
          () => remote.fetchClientAgentToken(agentId: any(named: 'agentId')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await repository.getToken(
          userId: userId,
          agentId: agentId,
        );

        check(result.isError()).isTrue();
        check(result.exceptionOrNull()).isA<NetworkFailure>();
      },
    );

    test('rejects empty agentId locally', () async {
      final result = await repository.getToken(userId: userId, agentId: '   ');
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(
        () => remote.fetchClientAgentToken(agentId: any(named: 'agentId')),
      );
    });
  });

  group('saveToken', () {
    test('saves to server and mirrors into local cache', () async {
      when(
        () => remote.putClientAgentToken(
          agentId: any(named: 'agentId'),
          request: any(named: 'request'),
        ),
      ).thenAnswer(
        (_) async => const ClientAgentTokenResponseDto(
          agentId: agentId,
          clientToken: 'tok',
        ),
      );

      final result = await repository.saveToken(
        userId: userId,
        agentId: agentId,
        clientToken: '  tok  ',
      );

      check(result.getOrNull()?.token).equals('tok');
      final captured =
          verify(
                () => secure.write(
                  key: any(named: 'key', that: contains(agentId)),
                  value: captureAny(named: 'value'),
                ),
              ).captured.single
              as String;
      check(captured.contains('"token":"tok"')).isTrue();
    });

    test('rejects token over the server cap before any HTTP call', () async {
      final long = 'a' * (ClientAgentTokenRequestDto.maxTokenLength + 1);
      final result = await repository.saveToken(
        userId: userId,
        agentId: agentId,
        clientToken: long,
      );

      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(
        () => remote.putClientAgentToken(
          agentId: any(named: 'agentId'),
          request: any(named: 'request'),
        ),
      );
      verifyNever(
        () => secure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('returns mapped failure on 403 (no local mirroring)', () async {
      when(
        () => remote.putClientAgentToken(
          agentId: any(named: 'agentId'),
          request: any(named: 'request'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.saveToken(
        userId: userId,
        agentId: agentId,
        clientToken: 'tok',
      );

      check(result.exceptionOrNull()).isA<AuthorizationFailure>();
      verifyNever(
        () => secure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });
  });

  group('removeToken', () {
    test('clears server and local cache', () async {
      when(
        () => remote.putClientAgentToken(
          agentId: any(named: 'agentId'),
          request: any(named: 'request'),
        ),
      ).thenAnswer(
        (_) async => const ClientAgentTokenResponseDto(
          agentId: agentId,
          clientToken: null,
        ),
      );

      final result = await repository.removeToken(
        userId: userId,
        agentId: agentId,
      );

      check(result.isSuccess()).isTrue();
      verify(
        () => secure.delete(
          key: any(named: 'key', that: contains(agentId)),
        ),
      ).called(1);
    });

    test('does not delete local cache when server PUT fails', () async {
      when(
        () => remote.putClientAgentToken(
          agentId: any(named: 'agentId'),
          request: any(named: 'request'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.removeToken(
        userId: userId,
        agentId: agentId,
      );

      check(result.exceptionOrNull()).isA<NetworkFailure>();
      verifyNever(() => secure.delete(key: any(named: 'key')));
    });
  });

  group('readMany (AgentClientTokenReader bridge)', () {
    test(
      'returns local tokens without remote hydration when cache is warm',
      () async {
        when(
          () => secure.read(key: any(named: 'key')),
        ).thenAnswer(
          (_) async => _storedTokenEnvelope(
            'tok',
            savedAt: DateTime.now().toUtc(),
          ),
        );

        final map = await repository.readMany(
          userId: userId,
          agentIds: <String>[agentId],
        );

        check(map.length).equals(1);
        check(map[agentId]).equals('tok');
        verifyNever(
          () => remote.fetchClientAgentToken(agentId: any(named: 'agentId')),
        );
      },
    );

    test(
      'hydrates missing local tokens from server and mirrors cache',
      () async {
        const secondAgentId = '22222222-2222-2222-8222-222222222222';
        when(
          () => secure.read(key: any(named: 'key')),
        ).thenAnswer((_) async => null);
        when(
          () => remote.fetchClientAgentToken(agentId: any(named: 'agentId')),
        ).thenAnswer((invocation) async {
          final id = invocation.namedArguments[#agentId] as String;
          return ClientAgentTokenResponseDto(
            agentId: id,
            clientToken: 'tok-$id',
          );
        });

        final map = await repository.readMany(
          userId: userId,
          agentIds: const <String>[agentId, secondAgentId],
        );

        check(map.length).equals(2);
        check(map[agentId]).equals('tok-$agentId');
        check(map[secondAgentId]).equals('tok-$secondAgentId');
        verify(
          () => remote.fetchClientAgentToken(agentId: agentId),
        ).called(1);
        verify(
          () => remote.fetchClientAgentToken(agentId: secondAgentId),
        ).called(1);
        verify(
          () => secure.write(
            key: any(named: 'key', that: contains(agentId)),
            value: any(named: 'value'),
          ),
        ).called(1);
        verify(
          () => secure.write(
            key: any(named: 'key', that: contains(secondAgentId)),
            value: any(named: 'value'),
          ),
        ).called(1);
      },
    );

    test('revalidates stale local token and updates the cache', () async {
      when(
        () => secure.read(key: any(named: 'key')),
      ).thenAnswer(
        (_) async => _storedTokenEnvelope(
          'stale-token',
          savedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
        ),
      );
      when(
        () => remote.fetchClientAgentToken(agentId: agentId),
      ).thenAnswer(
        (_) async => const ClientAgentTokenResponseDto(
          agentId: agentId,
          clientToken: 'fresh-token',
        ),
      );

      final map = await repository.readMany(
        userId: userId,
        agentIds: const <String>[agentId],
      );

      check(map[agentId]).equals('fresh-token');
      verify(() => remote.fetchClientAgentToken(agentId: agentId)).called(1);
    });

    test(
      'authoritative 403 hydration clears local token and excludes it',
      () async {
        when(
          () => secure.read(key: any(named: 'key')),
        ).thenAnswer(
          (_) async => _storedTokenEnvelope(
            'stale-token',
            savedAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 2),
            ),
          ),
        );
        when(
          () => remote.fetchClientAgentToken(agentId: agentId),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            response: Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: 403,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final map = await repository.readMany(
          userId: userId,
          agentIds: const <String>[agentId],
        );

        check(map.containsKey(agentId)).isFalse();
        verify(
          () => secure.delete(
            key: any(named: 'key', that: contains(agentId)),
          ),
        ).called(1);
      },
    );

    test(
      'keeps a stale local token when revalidation fails transiently',
      () async {
        when(
          () => secure.read(key: any(named: 'key')),
        ).thenAnswer(
          (_) async => _storedTokenEnvelope(
            'stale-token',
            savedAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 2),
            ),
          ),
        );
        when(
          () => remote.fetchClientAgentToken(agentId: agentId),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.connectionError,
          ),
        );

        final map = await repository.readMany(
          userId: userId,
          agentIds: const <String>[agentId],
        );

        check(map[agentId]).equals('stale-token');
        verifyNever(
          () => secure.delete(
            key: any(named: 'key', that: contains(agentId)),
          ),
        );
      },
    );

    test(
      'keeps readMany resilient when hydration fails for one agent',
      () async {
        const secondAgentId = '22222222-2222-2222-8222-222222222222';
        when(
          () => secure.read(key: any(named: 'key')),
        ).thenAnswer((_) async => null);
        when(() => remote.fetchClientAgentToken(agentId: agentId)).thenAnswer(
          (_) async => const ClientAgentTokenResponseDto(
            agentId: agentId,
            clientToken: 'tok',
          ),
        );
        when(
          () => remote.fetchClientAgentToken(agentId: secondAgentId),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.connectionError,
          ),
        );

        final map = await repository.readMany(
          userId: userId,
          agentIds: const <String>[agentId, secondAgentId],
        );

        check(map.length).equals(1);
        check(map[agentId]).equals('tok');
        check(map.containsKey(secondAgentId)).isFalse();
      },
    );
  });
}
