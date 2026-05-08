import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapToAppFailure', () {
    test('should preserve existing app failure', () {
      const failure = SessionFailure(
        message: 'Stored session has expired',
        userMessage: 'Sua sessao expirou.',
      );

      check(mapToAppFailure(failure)).equals(failure);
    });

    test('should map validation exception to validation failure', () {
      final failure = mapToAppFailure(
        _captureValidationError(),
      );

      check(failure).isA<ValidationFailure>();
      check(failure.displayMessage).contains('email');
    });

    test('should map unknown exceptions to clear client message', () {
      final failure = mapToAppFailure(
        StateError('boom'),
      );

      check(failure).isA<UnknownFailure>();
      check(failure.displayMessage).equals(
        'Ocorreu um erro inesperado. Tente novamente.',
      );
    });

    test('should prefer API message from Dio response body', () {
      final failure = mapToAppFailure(
        DioException(
          requestOptions: RequestOptions(path: '/client-auth/login'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/client-auth/login'),
            statusCode: 403,
            data: <String, dynamic>{
              'message': 'Sua conta esta pendente de aprovacao.',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      check(failure).isA<AuthorizationFailure>();
      check(failure.displayMessage).equals(
        'Sua conta esta pendente de aprovacao.',
      );
      final body =
          failure.context[DioHttpFailureContext.responseBodyField]! as Map;
      check(body['message']).equals('Sua conta esta pendente de aprovacao.');
    });

    test(
      'should classify blocked account responses separately from permission',
      () {
        final failure = mapToAppFailure(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/agents/commands'),
            response: Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/api/v1/agents/commands'),
              statusCode: 403,
              data: <String, dynamic>{
                'message': 'Account is blocked',
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        check(failure).isA<AuthorizationFailure>();
        check(isBlockedAccountFailure(failure)).isTrue();
        check(failure.displayMessage).equals(
          'Sua conta esta bloqueada. Entre em contato com o administrador.',
        );
        final body =
            failure.context[DioHttpFailureContext.responseBodyField]! as Map;
        check(body['message']).equals('Account is blocked');
      },
    );

    test('should attach string 403 bodies to httpResponseBody context', () {
      final failure = mapToAppFailure(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/agents/commands'),
          response: Response<String>(
            requestOptions: RequestOptions(path: '/api/v1/agents/commands'),
            statusCode: 403,
            data:
                'You do not have access to agent 3183a9f2-429b-46d6-a339-3580e5e5cb31',
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      check(failure).isA<AuthorizationFailure>();
      check(failure.displayMessage).equals(
        'You do not have access to agent 3183a9f2-429b-46d6-a339-3580e5e5cb31',
      );
      check(failure.context[DioHttpFailureContext.responseBodyField]).equals(
        'You do not have access to agent 3183a9f2-429b-46d6-a339-3580e5e5cb31',
      );
    });

    test('should join validation errors from Dio response body', () {
      final failure = mapToAppFailure(
        DioException(
          requestOptions: RequestOptions(path: '/client-auth/register'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/client-auth/register'),
            statusCode: 400,
            data: <String, dynamic>{
              'errors': <String, dynamic>{
                'email': <String>['must be a valid email'],
                'password': <String>['must contain uppercase'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      check(failure.displayMessage).equals(
        'email: must be a valid email\npassword: must contain uppercase',
      );
    });

    test(
      'should map 409 AGENT_DOCUMENT_CONFLICT to validation failure',
      () {
        final failure = mapToAppFailure(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/agents/x/profile'),
            response: Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/api/v1/agents/x/profile'),
              statusCode: 409,
              data: <String, dynamic>{
                'code': 'AGENT_DOCUMENT_CONFLICT',
                'message': 'ignored for this branch',
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        check(failure).isA<ValidationFailure>();
        check(failure.displayMessage).equals('Agent document conflict');
        check(failure.context['httpStatusCode']).equals(409);
        check(failure.context['apiErrorCode']).equals(
          'AGENT_DOCUMENT_CONFLICT',
        );
      },
    );

    test('should map other 409 responses to network failure', () {
      final failure = mapToAppFailure(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/other'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/api/v1/other'),
            statusCode: 409,
            data: <String, dynamic>{
              'message': 'Some other conflict',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      check(failure).isA<NetworkFailure>();
      check(failure.displayMessage).equals('Some other conflict');
    });

    test(
      'should map 409 AGENT_PROFILE_CAS_MISMATCH to validation failure',
      () {
        final failure = mapToAppFailure(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/agents/x/profile'),
            response: Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/api/v1/agents/x/profile'),
              statusCode: 409,
              data: <String, dynamic>{
                'code': 'AGENT_PROFILE_CAS_MISMATCH',
                'message': 'Profile version mismatch',
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        check(failure).isA<ValidationFailure>();
        check(failure.context['apiErrorCode']).equals(
          'AGENT_PROFILE_CAS_MISMATCH',
        );
      },
    );

    test('should propagate Retry-After header (delta seconds) on 429', () {
      final failure = mapToAppFailure(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/agents/commands'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(
              path: '/api/v1/agents/commands',
            ),
            statusCode: 429,
            headers: Headers.fromMap(<String, List<String>>{
              'retry-after': <String>['42'],
            }),
            data: <String, dynamic>{'message': 'rate limited'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      check(failure).isA<NetworkFailure>();
      check((failure as NetworkFailure).retryAfter).equals(
        const Duration(seconds: 42),
      );
    });

    test(
      'should propagate retry_after_ms from JSON-RPC error.data',
      () {
        final failure = mapToAppFailure(
          DioException(
            requestOptions: RequestOptions(
              path: '/api/v1/agents/commands',
            ),
            response: Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(
                path: '/api/v1/agents/commands',
              ),
              statusCode: 503,
              data: <String, dynamic>{
                'error': <String, dynamic>{
                  'code': -32013,
                  'message': 'rate limited',
                  'data': <String, dynamic>{
                    'retry_after_ms': 1500,
                  },
                },
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        check(failure).isA<NetworkFailure>();
        check((failure as NetworkFailure).retryAfter).equals(
          const Duration(milliseconds: 1500),
        );
      },
    );

    test(
      'merges extra context when re-mapping an existing AppFailure',
      () {
        // Regression: a re-throw chain that wants to add a breadcrumb
        // (e.g. `operation: 'foo'`) used to silently drop the new
        // context whenever the exception was already an AppFailure.
        const original = NetworkFailure(
          message: 'down',
          userMessage: 'down',
          context: <String, Object?>{'origin': 'remote'},
        );
        final remapped = mapToAppFailure(
          original,
          context: <String, Object?>{'operation': 'loadOverview'},
        );
        check(remapped).isA<NetworkFailure>();
        check(remapped.context['origin']).equals('remote');
        check(remapped.context['operation']).equals('loadOverview');
      },
    );

    test(
      'returns the original AppFailure unchanged when no extra context',
      () {
        const original = SessionFailure(
          message: 'expired',
          userMessage: 'expired',
        );
        // Identity check — the no-extra-context path must not allocate
        // a new failure (cheap path for the typical re-throw).
        check(identical(mapToAppFailure(original), original)).isTrue();
      },
    );
  });

  group('appFailureWithMergedContext', () {
    test(
      'preserves NetworkFailure.retryAfter when merging context '
      '(regression: was silently dropped before fix)',
      () {
        const original = NetworkFailure(
          message: 'rate limited',
          userMessage: 'rate limited',
          retryAfter: Duration(seconds: 7),
          context: <String, Object?>{'origin': 'remote'},
        );
        final merged = appFailureWithMergedContext(
          original,
          <String, Object?>{'operation': 'loadOverview'},
        );
        check(merged).isA<NetworkFailure>();
        // retryAfter MUST survive — `RetryAfterGate` reads it via
        // `appFailureRetryAfter` and arms the cooldown. Dropping it
        // here would silently disable the UX countdown.
        check((merged as NetworkFailure).retryAfter).equals(
          const Duration(seconds: 7),
        );
        check(appFailureRetryAfter(merged)).equals(const Duration(seconds: 7));
        // And the context is properly merged.
        check(merged.context['origin']).equals('remote');
        check(merged.context['operation']).equals('loadOverview');
      },
    );

    test(
      'preserves RpcFailure.retryAfter and isTransient (retryable) '
      'when merging context',
      () {
        const original = RpcFailure(
          message: 'rate limited',
          userMessage: 'rate limited',
          rpcCode: -32013,
          retryable: true,
          retryAfter: Duration(milliseconds: 1500),
          reason: 'client_token_get_policy_rate_limited',
        );
        final merged = appFailureWithMergedContext(
          original,
          <String, Object?>{'operation': 'loadOverview'},
        );
        check(merged).isA<RpcFailure>();
        check(
          (merged as RpcFailure).retryAfter,
        ).equals(const Duration(milliseconds: 1500));
        check(merged.retryable).isTrue();
        check(merged.isTransient).isTrue();
        check(merged.rpcCode).equals(-32013);
        check(merged.reason).equals('client_token_get_policy_rate_limited');
        check(
          appFailureRetryAfter(merged),
        ).equals(const Duration(milliseconds: 1500));
      },
    );

    test('later keys overwrite earlier context entries', () {
      const original = ValidationFailure(
        message: 'bad input',
        context: <String, Object?>{'field': 'email', 'attempt': 1},
      );
      final merged = appFailureWithMergedContext(
        original,
        <String, Object?>{'attempt': 2, 'operation': 'register'},
      );
      check(merged.context['field']).equals('email');
      check(merged.context['attempt']).equals(2);
      check(merged.context['operation']).equals('register');
    });
  });
}

Object _captureValidationError() {
  try {
    EmailAddress('invalid-email');
  } on Object catch (error) {
    return error;
  }

  throw StateError('Expected validation error');
}
