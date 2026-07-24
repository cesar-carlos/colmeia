import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/socket_app_error_retry_after.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractRetryAfterFromAppError', () {
    test('reads top-level retryAfterMs (camel)', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'code': 'SERVICE_UNAVAILABLE',
        'message': 'shed load',
        'retryAfterMs': 1500,
      });
      check(result).equals(const Duration(milliseconds: 1500));
    });

    test('reads top-level retry_after_ms (snake)', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'code': 'SERVICE_UNAVAILABLE',
        'retry_after_ms': 750,
      });
      check(result).equals(const Duration(milliseconds: 750));
    });

    test('reads data.retry_after_ms when bridge flattens to root', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'code': 'RATE_LIMITED',
        'data': <String, Object?>{
          'retry_after_ms': 2000,
        },
      });
      check(result).equals(const Duration(milliseconds: 2000));
    });

    test('reads error.retryAfterMs (agents:command overload shed)', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'success': false,
        'requestId': 'rpc-1',
        'error': <String, Object?>{
          'code': 'SERVICE_UNAVAILABLE',
          'message': 'Consumer namespace temporarily overloaded',
          'statusCode': 503,
          'retryAfterMs': 1250,
        },
      });
      check(result).equals(const Duration(milliseconds: 1250));
    });

    test('reads error.data.retry_after_ms (standard JSON-RPC envelope)', () {
      // -32013 RATE_LIMITED / client_token.getPolicy responses ship the
      // hint nested under `error.data`.
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'error': <String, Object?>{
          'code': -32013,
          'data': <String, Object?>{
            'retry_after_ms': 3500,
          },
        },
      });
      check(result).equals(const Duration(milliseconds: 3500));
    });

    test('parses string retry_after_ms (numeric inside text)', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'retry_after_ms': '900',
      });
      check(result).equals(const Duration(milliseconds: 900));
    });

    test('treats negative ms as Duration.zero (defensive floor)', () {
      // Some servers report `0` or even negative when "you can retry now".
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'retryAfterMs': -50,
      });
      check(result).equals(Duration.zero);
    });

    test('returns null when no hint is present', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'code': 'RATE_LIMITED',
        'message': 'no hint here',
      });
      check(result).isNull();
    });

    test('returns null on empty / non-numeric strings', () {
      check(
        extractRetryAfterFromAppError(<String, Object?>{
          'retry_after_ms': '',
        }),
      ).isNull();
      check(
        extractRetryAfterFromAppError(<String, Object?>{
          'retry_after_ms': 'soon',
        }),
      ).isNull();
    });

    test('camel takes precedence over snake when both top-level', () {
      // Documents the precedence order — `retryAfterMs` is the canonical
      // shape used by the hub's overload responses; `retry_after_ms`
      // exists for forward compat.
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'retryAfterMs': 100,
        'retry_after_ms': 200,
      });
      check(result).equals(const Duration(milliseconds: 100));
    });

    test('reads top-level retryAfterSeconds', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'code': 'SERVICE_UNAVAILABLE',
        'retryAfterSeconds': 12,
      });
      check(result).equals(const Duration(seconds: 12));
    });

    test('millisecond fields take precedence over seconds', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'retryAfterMs': 500,
        'retryAfterSeconds': 12,
      });
      check(result).equals(const Duration(milliseconds: 500));
    });

    test('reads error.retry_after_seconds', () {
      final result = extractRetryAfterFromAppError(<String, Object?>{
        'error': <String, Object?>{
          'code': 'SERVICE_UNAVAILABLE',
          'retry_after_seconds': 3,
        },
      });
      check(result).equals(const Duration(seconds: 3));
    });
  });
}
