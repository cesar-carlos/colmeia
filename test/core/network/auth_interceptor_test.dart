import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/core/network/auth_interceptor.dart';
import 'package:colmeia/core/network/auth_refresh_coordinator.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class _TestHttpClientAdapter implements HttpClientAdapter {
  _TestHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}

const _authorizationHeader = 'Authorization';

void main() {
  final fallbackSession = AuthSessionModel(
    userId: 'user-fallback',
    email: 'fallback@client.com',
    accessToken: 'fallback-access-token',
    refreshToken: 'fallback-refresh-token',
    expiresAt: DateTime.utc(2030),
  );

  setUpAll(() {
    registerFallbackValue(fallbackSession);
  });

  group('AuthInterceptor', () {
    late _MockAuthLocalDataSource localDataSource;
    late AuthSessionAccessor accessor;
    late AuthSessionEvents sessionEvents;
    late Dio refreshDio;
    late AuthRefreshCoordinator refreshCoordinator;
    late Dio dio;

    setUp(() {
      localDataSource = _MockAuthLocalDataSource();
      accessor = AuthSessionAccessor(localDataSource);
      sessionEvents = AuthSessionEvents();
      refreshDio = AppDioClient.create();
      refreshCoordinator = AuthRefreshCoordinator(
        refreshDio: refreshDio,
        sessionAccessor: accessor,
        sessionEvents: sessionEvents,
      );
      dio = AppDioClient.create();
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          sessionAccessor: accessor,
          refreshCoordinator: refreshCoordinator,
        ),
      );
    });

    test('should attach bearer automatically on authenticated route', () async {
      final session = AuthSessionModel(
        userId: 'client-1',
        email: 'client@corp.com',
        accessToken: 'access-token-1',
        refreshToken: 'refresh-token-1',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(
        () => localDataSource.readSession(),
      ).thenAnswer((_) async => session);

      String? authorizationHeader;
      dio.httpClientAdapter = _TestHttpClientAdapter((options) async {
        authorizationHeader = options.headers[_authorizationHeader] as String?;
        return _jsonBody(<String, Object?>{'ok': true});
      });

      await dio.get<Map<String, dynamic>>(ClientAuthApiRoutes.me);

      expect(authorizationHeader, equals('Bearer ${session.accessToken}'));
    });

    test('should skip bearer injection for public login route', () async {
      final session = AuthSessionModel(
        userId: 'client-1',
        email: 'client@corp.com',
        accessToken: 'access-token-1',
        refreshToken: 'refresh-token-1',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(
        () => localDataSource.readSession(),
      ).thenAnswer((_) async => session);

      String? authorizationHeader;
      dio.httpClientAdapter = _TestHttpClientAdapter((options) async {
        authorizationHeader = options.headers[_authorizationHeader] as String?;
        return _jsonBody(<String, Object?>{'ok': true});
      });

      await dio.post<Map<String, dynamic>>(
        ClientAuthApiRoutes.login,
        data: <String, Object?>{
          'email': 'client@corp.com',
          'password': '123456',
        },
      );

      expect(authorizationHeader, isNull);
    });

    test(
      'should refresh and retry original request on 401 '
      '(server-side revocation of a still-valid token)',
      () async {
        // Use a token that is locally NOT inside the proactive
        // refresh window (`expiresAt` 1 h ahead), so the
        // interceptor's `onRequest` does not refresh upfront.
        // This isolates the legacy 401 → refresh → retry path.
        final session = AuthSessionModel(
          userId: 'client-1',
          email: 'client@corp.com',
          accessToken: 'still-valid-locally-token',
          refreshToken: 'refresh-token-1',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        when(
          () => localDataSource.readSession(),
        ).thenAnswer((_) async => session);
        when(
          () => localDataSource.saveSession(any()),
        ).thenAnswer((_) async {});

        var refreshCalls = 0;
        refreshDio.httpClientAdapter = _TestHttpClientAdapter((options) async {
          refreshCalls += 1;
          return _jsonBody(<String, Object?>{
            'accessToken': 'new-access-token',
            'refreshToken': 'new-refresh-token',
            'expiresAt': DateTime.now()
                .add(const Duration(hours: 1))
                .toIso8601String(),
          });
        });

        var profileCalls = 0;
        dio.httpClientAdapter = _TestHttpClientAdapter((options) async {
          profileCalls += 1;
          final authorization =
              options.headers[_authorizationHeader] as String?;
          final isRefreshedToken = authorization == 'Bearer new-access-token';
          if (!isRefreshedToken) {
            return _jsonBody(<String, Object?>{
              'error': 'expired',
            }, statusCode: 401);
          }
          return _jsonBody(<String, Object?>{'ok': true});
        });

        final response = await dio.get<Map<String, dynamic>>(
          ClientAuthApiRoutes.me,
        );

        expect(response.statusCode, equals(200));
        expect(refreshCalls, equals(1));
        expect(profileCalls, equals(2));
        verify(() => localDataSource.saveSession(any())).called(1);
      },
    );

    test(
      'should refresh proactively when token is inside the refresh '
      'window (no 401 round-trip)',
      () async {
        // Token still technically valid (expiresAt > now) but inside
        // the proactive window — interceptor must refresh BEFORE the
        // request is sent so the user does not pay the 401 → refresh
        // → retry round-trip on every authenticated call.
        final fixedNow = DateTime.utc(2026, 4, 18, 10, 0, 0);
        final session = AuthSessionModel(
          userId: 'client-1',
          email: 'client@corp.com',
          accessToken: 'about-to-expire-token',
          refreshToken: 'refresh-token-1',
          // expiresAt 10s in the future; default proactive window is
          // 30s, so this counts as expiring.
          expiresAt: fixedNow.add(const Duration(seconds: 10)),
        );
        when(
          () => localDataSource.readSession(),
        ).thenAnswer((_) async => session);
        when(
          () => localDataSource.saveSession(any()),
        ).thenAnswer((_) async {});

        // Rewire the interceptor with a fixed clock so the test does
        // not race with real time.
        dio.interceptors.clear();
        dio.interceptors.add(
          AuthInterceptor(
            dio: dio,
            sessionAccessor: accessor,
            refreshCoordinator: refreshCoordinator,
            clock: () => fixedNow,
          ),
        );

        var refreshCalls = 0;
        refreshDio.httpClientAdapter = _TestHttpClientAdapter((options) async {
          refreshCalls += 1;
          // After refresh, the accessor still returns the OLD session
          // because we use a single mock — we override the read here
          // to give the second read (post-refresh) the fresh token.
          when(
            () => localDataSource.readSession(),
          ).thenAnswer(
            (_) async => AuthSessionModel(
              userId: session.userId,
              email: session.email,
              accessToken: 'fresh-token',
              refreshToken: 'fresh-refresh',
              expiresAt: fixedNow.add(const Duration(hours: 1)),
            ),
          );
          return _jsonBody(<String, Object?>{
            'accessToken': 'fresh-token',
            'refreshToken': 'fresh-refresh',
            'expiresAt': fixedNow
                .add(const Duration(hours: 1))
                .toIso8601String(),
          });
        });

        var profileCalls = 0;
        String? sentAuthHeader;
        dio.httpClientAdapter = _TestHttpClientAdapter((options) async {
          profileCalls += 1;
          sentAuthHeader = options.headers[_authorizationHeader] as String?;
          return _jsonBody(<String, Object?>{'ok': true});
        });

        final response = await dio.get<Map<String, dynamic>>(
          ClientAuthApiRoutes.me,
        );

        expect(response.statusCode, equals(200));
        expect(refreshCalls, equals(1));
        // Critical: only ONE outbound profile call, with the FRESH
        // token. No 401 round-trip happened.
        expect(profileCalls, equals(1));
        expect(sentAuthHeader, equals('Bearer fresh-token'));
      },
    );

    test(
      'should NOT refresh proactively when token has plenty of life',
      () async {
        final fixedNow = DateTime.utc(2026, 4, 18, 10, 0, 0);
        final session = AuthSessionModel(
          userId: 'client-1',
          email: 'client@corp.com',
          accessToken: 'fresh-token',
          refreshToken: 'refresh-token-1',
          expiresAt: fixedNow.add(const Duration(hours: 1)),
        );
        when(
          () => localDataSource.readSession(),
        ).thenAnswer((_) async => session);

        dio.interceptors.clear();
        dio.interceptors.add(
          AuthInterceptor(
            dio: dio,
            sessionAccessor: accessor,
            refreshCoordinator: refreshCoordinator,
            clock: () => fixedNow,
          ),
        );

        var refreshCalls = 0;
        refreshDio.httpClientAdapter = _TestHttpClientAdapter((options) async {
          refreshCalls += 1;
          return _jsonBody(<String, Object?>{}, statusCode: 500);
        });

        dio.httpClientAdapter = _TestHttpClientAdapter((options) async {
          return _jsonBody(<String, Object?>{'ok': true});
        });

        await dio.get<Map<String, dynamic>>(ClientAuthApiRoutes.me);

        expect(refreshCalls, equals(0));
      },
    );

    test(
      'proactive refresh failure falls back to sending the stale token',
      () async {
        // Resilience: if the refresh server is briefly unavailable
        // we must still send the request with the existing token —
        // the 401 retry path then takes over if the server rejects
        // it. Otherwise a flaky refresh blocks ALL traffic.
        final fixedNow = DateTime.utc(2026, 4, 18, 10, 0, 0);
        final session = AuthSessionModel(
          userId: 'client-1',
          email: 'client@corp.com',
          accessToken: 'about-to-expire',
          refreshToken: 'refresh-token-1',
          expiresAt: fixedNow.add(const Duration(seconds: 10)),
        );
        when(
          () => localDataSource.readSession(),
        ).thenAnswer((_) async => session);

        dio.interceptors.clear();
        dio.interceptors.add(
          AuthInterceptor(
            dio: dio,
            sessionAccessor: accessor,
            refreshCoordinator: refreshCoordinator,
            clock: () => fixedNow,
          ),
        );

        refreshDio.httpClientAdapter = _TestHttpClientAdapter((options) async {
          return _jsonBody(<String, Object?>{}, statusCode: 500);
        });

        String? sentAuthHeader;
        dio.httpClientAdapter = _TestHttpClientAdapter((options) async {
          sentAuthHeader = options.headers[_authorizationHeader] as String?;
          return _jsonBody(<String, Object?>{'ok': true});
        });

        await dio.get<Map<String, dynamic>>(ClientAuthApiRoutes.me);

        // The stale token went out — 401 path can take over from here.
        expect(sentAuthHeader, equals('Bearer about-to-expire'));
      },
    );

    test('should not retry multipart requests on 401', () async {
      final session = AuthSessionModel(
        userId: 'client-1',
        email: 'client@corp.com',
        accessToken: 'expired-access-token',
        refreshToken: 'refresh-token-1',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );
      when(
        () => localDataSource.readSession(),
      ).thenAnswer((_) async => session);

      var refreshCalls = 0;
      refreshDio.httpClientAdapter = _TestHttpClientAdapter((options) async {
        refreshCalls += 1;
        return _jsonBody(<String, Object?>{
          'accessToken': 'new-access-token',
          'refreshToken': 'new-refresh-token',
          'expiresAt': DateTime.now()
              .add(const Duration(hours: 1))
              .toIso8601String(),
        });
      });

      var uploadCalls = 0;
      dio.httpClientAdapter = _TestHttpClientAdapter((options) async {
        uploadCalls += 1;
        return _jsonBody(<String, Object?>{
          'error': 'expired',
        }, statusCode: 401);
      });

      await expectLater(
        () => dio.post<Map<String, dynamic>>(
          ClientAuthApiRoutes.thumbnail,
          data: FormData.fromMap(<String, Object?>{
            'thumbnail': MultipartFile.fromBytes(<int>[1, 2, 3]),
          }),
        ),
        throwsA(isA<DioException>()),
      );

      expect(refreshCalls, equals(0));
      expect(uploadCalls, equals(1));
    });
  });

  group('AuthRefreshCoordinator', () {
    test('should perform a single refresh for concurrent calls', () async {
      final localDataSource = _MockAuthLocalDataSource();
      final accessor = AuthSessionAccessor(localDataSource);
      final sessionEvents = AuthSessionEvents();
      final session = AuthSessionModel(
        userId: 'client-1',
        email: 'client@corp.com',
        accessToken: 'expired-access-token',
        refreshToken: 'refresh-token-1',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );
      when(localDataSource.readSession).thenAnswer((_) async => session);
      when(() => localDataSource.saveSession(any())).thenAnswer((_) async {});

      var refreshCalls = 0;
      final refreshDio = AppDioClient.create()
        ..httpClientAdapter = _TestHttpClientAdapter((options) async {
          refreshCalls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return _jsonBody(<String, Object?>{
            'accessToken': 'new-access-token',
            'refreshToken': 'new-refresh-token',
            'expiresAt': DateTime.now()
                .add(const Duration(hours: 1))
                .toIso8601String(),
          });
        });

      final coordinator = AuthRefreshCoordinator(
        refreshDio: refreshDio,
        sessionAccessor: accessor,
        sessionEvents: sessionEvents,
      );

      final results = await Future.wait<String?>(<Future<String?>>[
        coordinator.refreshAccessToken(),
        coordinator.refreshAccessToken(),
      ]);

      expect(results, everyElement(equals('new-access-token')));
      expect(refreshCalls, equals(1));
      verify(() => localDataSource.saveSession(any())).called(1);
    });

    test(
      'should clear session and emit invalidation when refresh fails',
      () async {
        final localDataSource = _MockAuthLocalDataSource();
        final accessor = AuthSessionAccessor(localDataSource);
        final sessionEvents = AuthSessionEvents();
        final session = AuthSessionModel(
          userId: 'client-1',
          email: 'client@corp.com',
          accessToken: 'expired-access-token',
          refreshToken: 'refresh-token-1',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 2)),
        );
        when(localDataSource.readSession).thenAnswer((_) async => session);
        when(localDataSource.clearSession).thenAnswer((_) async {});

        final refreshDio = AppDioClient.create()
          ..httpClientAdapter = _TestHttpClientAdapter((options) async {
            return _jsonBody(<String, Object?>{
              'error': 'invalid_refresh',
            }, statusCode: 401);
          });

        final coordinator = AuthRefreshCoordinator(
          refreshDio: refreshDio,
          sessionAccessor: accessor,
          sessionEvents: sessionEvents,
        );

        final eventFuture = sessionEvents.stream.first;

        await expectLater(
          coordinator.refreshAccessToken,
          throwsA(isA<DioException>()),
        );
        final event = await eventFuture;

        expect(event.type, equals(AuthSessionEventType.invalidated));
        verify(localDataSource.clearSession).called(1);
      },
    );

    test(
      'should preserve session when refresh fails with transient server error',
      () async {
        final localDataSource = _MockAuthLocalDataSource();
        final accessor = AuthSessionAccessor(localDataSource);
        final sessionEvents = AuthSessionEvents();
        final session = AuthSessionModel(
          userId: 'client-1',
          email: 'client@corp.com',
          accessToken: 'expired-access-token',
          refreshToken: 'refresh-token-1',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 2)),
        );
        when(localDataSource.readSession).thenAnswer((_) async => session);

        final refreshDio = AppDioClient.create()
          ..httpClientAdapter = _TestHttpClientAdapter((options) async {
            return _jsonBody(<String, Object?>{
              'error': 'temporary_failure',
            }, statusCode: 500);
          });

        final coordinator = AuthRefreshCoordinator(
          refreshDio: refreshDio,
          sessionAccessor: accessor,
          sessionEvents: sessionEvents,
        );

        var emittedEvent = false;
        final subscription = sessionEvents.stream.listen((_) {
          emittedEvent = true;
        });

        await expectLater(
          coordinator.refreshAccessToken,
          throwsA(isA<DioException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        verifyNever(localDataSource.clearSession);
        expect(emittedEvent, isFalse);
        await subscription.cancel();
      },
    );
  });
}

ResponseBody _jsonBody(
  Map<String, Object?> payload, {
  int statusCode = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}
