import 'dart:async';

import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/pwa/data/pwa_push_client.dart';
import 'package:colmeia/features/pwa/domain/push_subscription_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Platform extends Mock implements PwaPlatform {}

class _Dio extends Mock implements Dio {}

class _Preferences extends Mock implements SharedPreferences {}

void main() {
  late _Platform platform;
  late _Dio dio;
  late SharedPreferences preferences;
  late PwaPushClient client;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'pwa.installation.user': 'installation',
    });
    preferences = await SharedPreferences.getInstance();
    platform = _Platform();
    dio = _Dio();
    client = PwaPushClient(platform, dio, preferences);
    when(() => platform.online).thenReturn(false);
    when(() => platform.setPushEnabled(enabled: false))
        .thenAnswer((_) async {});
    when(() => platform.unsubscribe()).thenAnswer((_) async {});
    when(() => dio.delete<void>(any())).thenAnswer(
      (_) async =>
          Response(requestOptions: RequestOptions(path: '/'), statusCode: 204),
    );
  });
  test('offline logout disables local notifications and defers authenticated removal', () async {
    await client.disable('user');
    verify(() => platform.setPushEnabled(enabled: false)).called(1);
    verify(() => platform.unsubscribe()).called(1);
    expect(preferences.getString('pwa.pushRemoval.user'), 'installation');
    verifyNever(() => dio.delete<void>(any()));
    when(() => platform.online).thenReturn(true);
    await client.reconcile('other');
    verifyNever(() => dio.delete<void>(any()));
    await client.reconcile('user');
    verify(() => dio.delete<void>('/client/me/pwa/subscriptions/installation'))
        .called(1);
    expect(preferences.getString('pwa.pushRemoval.user'), isNull);
  });
  test('worker failure still attempts browser unsubscribe and preserves removal marker', () async {
    when(() => platform.setPushEnabled(enabled: false))
        .thenThrow(StateError('worker unavailable'));
    await expectLater(client.disable('user'), throwsStateError);
    verify(() => platform.unsubscribe()).called(1);
    expect(preferences.getBool('pwa.pushEnabled.user'), isFalse);
    expect(preferences.getString('pwa.pushRemoval.user'), 'installation');
  });
  test('failed server removal remains pending for the same user', () async {
    await client.disable('user');
    when(() => platform.online).thenReturn(true);
    when(() => dio.delete<void>(any()))
        .thenThrow(DioException(requestOptions: RequestOptions(path: '/')));
    await expectLater(client.reconcile('user'), throwsA(isA<DioException>()));
    expect(preferences.getString('pwa.pushRemoval.user'), 'installation');
    when(() => dio.delete<void>(any())).thenAnswer(
      (_) async => Response<void>(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 204,
      ),
    );
    await client.reconcile('user');
    expect(preferences.getString('pwa.pushRemoval.user'), isNull);
    verify(() => dio.delete<void>(any())).called(2);
  });
  test('should share concurrent removal requests for the same user', () async {
    await client.disable('user');
    when(() => platform.online).thenReturn(true);
    final response = Completer<Response<void>>();
    when(() => dio.delete<void>(any())).thenAnswer((_) => response.future);
    final first = client.reconcile('user');
    final second = client.reconcile('user');
    response.complete(
      Response<void>(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 204,
      ),
    );
    await Future.wait([first, second]);
    verify(() => dio.delete<void>(any())).called(1);
    expect(preferences.getString('pwa.pushRemoval.user'), isNull);
  });
  test(
    'should retain a newer removal when an older request finishes',
    () async {
      await client.disable('user');
      when(() => platform.online).thenReturn(true);
      final response = Completer<Response<void>>();
      when(() => dio.delete<void>(any())).thenAnswer((_) => response.future);
      final first = client.reconcile('user');
      when(() => platform.online).thenReturn(false);
      await client.disable('user');
      response.complete(
        Response<void>(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 204,
        ),
      );
      await first;
      expect(preferences.getString('pwa.pushRemoval.user'), 'installation');
      when(() => platform.online).thenReturn(true);
      await client.reconcile('user');
      expect(preferences.getString('pwa.pushRemoval.user'), isNull);
      verify(() => dio.delete<void>(any())).called(2);
    },
  );
  test('should unsubscribe when installation storage cannot be read', () async {
    final storage = _Preferences();
    when(() => storage.getString('pwa.installation.user'))
        .thenThrow(StateError('storage unavailable'));
    when(() => storage.setBool('pwa.pushEnabled.user', false))
        .thenAnswer((_) async => true);
    await expectLater(
      PwaPushClient(platform, dio, storage).disable('user'),
      throwsStateError,
    );
    verify(() => platform.setPushEnabled(enabled: false)).called(1);
    verify(() => platform.unsubscribe()).called(1);
  });
  for (final failedWrite in ['pending', 'disabled']) {
    for (final throws in [true, false]) {
      test(
        'should unsubscribe when $failedWrite storage ${throws ? 'throws' : 'rejects'}',
        () async {
          final storage = _Preferences();
          when(() => storage.getString('pwa.installation.user'))
              .thenReturn('installation');
          when(() => storage.setString('pwa.pushRemoval.user', 'installation'))
              .thenAnswer((_) async => true);
          when(() => storage.setBool('pwa.pushEnabled.user', false))
              .thenAnswer((_) async => true);
          if (failedWrite == 'pending') {
            when(
              () => storage.setString('pwa.pushRemoval.user', 'installation'),
            ).thenAnswer((_) async {
              if (throws) throw StateError('storage unavailable');
              return false;
            });
          } else {
            when(() => storage.setBool('pwa.pushEnabled.user', false))
                .thenAnswer((_) async {
                  if (throws) throw StateError('storage unavailable');
                  return false;
                });
          }
          final failing = PwaPushClient(platform, dio, storage);
          await expectLater(failing.disable('user'), throwsStateError);
          verify(() => platform.setPushEnabled(enabled: false)).called(1);
          verify(() => platform.unsubscribe()).called(1);
        },
      );
    }
  }
  for (final scenario in [
    (
      data: <String, dynamic>{'enabled': false},
      issue: PushSubscriptionIssue.serverDisabled,
    ),
    (
      data: <String, dynamic>{'enabled': true, 'publicKey': ''},
      issue: PushSubscriptionIssue.invalidResponse,
    ),
    (data: <String, dynamic>{}, issue: PushSubscriptionIssue.invalidResponse),
  ]) {
    test(
      'should report ${scenario.issue} before requesting browser permission',
      () async {
        when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/'),
            data: {'data': scenario.data},
          ),
        );
        await expectLater(
          client.enable('user'),
          throwsA(
            isA<PushSubscriptionException>().having(
              (e) => e.issue,
              'issue',
              scenario.issue,
            ),
          ),
        );
        verifyNever(() => platform.subscribe(any()));
        expect(preferences.getBool('pwa.pushEnabled.user'), isNull);
      },
    );
  }
  test('should report denied permission without enabling push', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/'),
        data: {
          'data': {'enabled': true, 'publicKey': 'key'},
        },
      ),
    );
    when(() => platform.subscribe('key')).thenAnswer((_) async => null);
    await expectLater(
      client.enable('user'),
      throwsA(
        isA<PushSubscriptionException>().having(
          (e) => e.issue,
          'issue',
          PushSubscriptionIssue.permissionDenied,
        ),
      ),
    );
    expect(preferences.getBool('pwa.pushEnabled.user'), isNull);
  });
}
