import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/repository_error_mapping.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('withRepositoryErrorMapping', () {
    test('returns Success when action completes', () async {
      final result = await withRepositoryErrorMapping<int>(
        action: () async => 42,
        fallbackMessage: 'unused',
        fallbackUserMessage: 'unused',
        context: const <String, Object?>{},
      );

      expect(result.isSuccess(), isTrue);
      expect(result.getOrNull(), 42);
    });

    test(
      'returns Failure mapped to AppFailure when action throws DioException',
      () async {
        final result = await withRepositoryErrorMapping<int>(
          action: () async {
            throw DioException(
              requestOptions: RequestOptions(path: '/x'),
              type: DioExceptionType.connectionError,
              message: 'boom',
            );
          },
          fallbackMessage: 'load failed',
          fallbackUserMessage: 'Algo deu errado.',
          context: const <String, Object?>{'operation': 'loadX'},
        );

        expect(result.isError(), isTrue);
        final failure = result.exceptionOrNull()!;
        expect(failure.message.isNotEmpty, isTrue);
        expect(failure.context['operation'], 'loadX');
      },
    );

    test(
      'falls back to cached value when remote fails with non-auth error',
      () async {
        DioException? observed;
        final result = await withRepositoryErrorMapping<int>(
          action: () async {
            throw DioException(
              requestOptions: RequestOptions(path: '/x'),
              type: DioExceptionType.connectionError,
            );
          },
          cacheFallback: (cause) async {
            observed = cause;
            return 7;
          },
          fallbackMessage: 'load failed',
          fallbackUserMessage: 'Algo deu errado.',
          context: const <String, Object?>{},
        );

        expect(result.isSuccess(), isTrue);
        expect(result.getOrNull(), 7);
        expect(observed, isNotNull);
        expect(observed!.type, DioExceptionType.connectionError);
      },
    );

    test(
      'does NOT consult cache when remote fails with HTTP 401',
      () async {
        var fallbackCalled = false;
        final result = await withRepositoryErrorMapping<int>(
          action: () async {
            throw DioException(
              requestOptions: RequestOptions(path: '/x'),
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 401,
              ),
            );
          },
          cacheFallback: (cause) async {
            fallbackCalled = true;
            return 7;
          },
          fallbackMessage: 'load failed',
          fallbackUserMessage: 'Sessao expirou.',
          context: const <String, Object?>{},
        );

        expect(fallbackCalled, isFalse);
        expect(result.isError(), isTrue);
      },
    );

    test(
      'does NOT consult cache when remote fails with HTTP 403',
      () async {
        var fallbackCalled = false;
        final result = await withRepositoryErrorMapping<int>(
          action: () async {
            throw DioException(
              requestOptions: RequestOptions(path: '/x'),
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: 403,
              ),
            );
          },
          cacheFallback: (cause) async {
            fallbackCalled = true;
            return 7;
          },
          fallbackMessage: 'load failed',
          fallbackUserMessage: 'Sem permissao.',
          context: const <String, Object?>{},
        );

        expect(fallbackCalled, isFalse);
        expect(result.isError(), isTrue);
      },
    );

    test(
      'returns mapped Failure when cacheFallback returns null',
      () async {
        final result = await withRepositoryErrorMapping<int>(
          action: () async {
            throw DioException(
              requestOptions: RequestOptions(path: '/x'),
              type: DioExceptionType.connectionError,
            );
          },
          cacheFallback: (cause) async => null,
          fallbackMessage: 'load failed',
          fallbackUserMessage: 'Sem dados.',
          context: const <String, Object?>{},
        );

        expect(result.isError(), isTrue);
      },
    );

    test(
      'falls back to cached value when action throws non-Dio Object',
      () async {
        final result = await withRepositoryErrorMapping<int>(
          action: () async => throw StateError('boom'),
          cacheFallback: (cause) async {
            expect(cause, isNull);
            return 99;
          },
          fallbackMessage: 'load failed',
          fallbackUserMessage: 'Algo deu errado.',
          context: const <String, Object?>{},
        );

        expect(result.isSuccess(), isTrue);
        expect(result.getOrNull(), 99);
      },
    );

    test(
      'when action throws AppFailure wrapping a 401 DioException, '
      'fallback is skipped',
      () async {
        var fallbackCalled = false;
        final result = await withRepositoryErrorMapping<int>(
          action: () async {
            throw AuthorizationFailure(
              message: 'forbidden',
              cause: DioException(
                requestOptions: RequestOptions(path: '/x'),
                response: Response<dynamic>(
                  requestOptions: RequestOptions(path: '/x'),
                  statusCode: 401,
                ),
              ),
            );
          },
          cacheFallback: (cause) async {
            fallbackCalled = true;
            return 7;
          },
          fallbackMessage: 'load failed',
          fallbackUserMessage: 'Sessao expirou.',
          context: const <String, Object?>{},
        );

        expect(fallbackCalled, isFalse);
        expect(result.isError(), isTrue);
      },
    );
  });
}
