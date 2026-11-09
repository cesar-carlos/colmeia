import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/security/app_crypto.dart';
import 'package:colmeia/core/storage/session_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('SessionStorage', () {
    late _MockFlutterSecureStorage secureStorage;
    late SessionStorage sessionStorage;

    setUp(() {
      secureStorage = _MockFlutterSecureStorage();
      sessionStorage = SessionStorage(secureStorage);
    });

    test('should wrap stored values with digest envelope', () async {
      when(
        () => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await sessionStorage.write(
        key: 'auth_session',
        value: 'raw-session',
      );

      final captured =
          verify(
                () => secureStorage.write(
                  key: 'auth_session',
                  value: captureAny(named: 'value'),
                ),
              ).captured.single
              as String;
      final envelope = jsonDecode(captured) as Map<String, dynamic>;

      check(envelope['payload']).equals('raw-session');
      check(envelope['digest']).equals(
        AppCrypto.hashSha256('raw-session'),
      );
    });

    test('should unwrap signed values with valid digest', () async {
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => _signedValue('raw-session'));

      final value = await sessionStorage.read('auth_session');

      check(value).equals('raw-session');
    });

    test('should keep reading legacy raw values', () async {
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'legacy-session');

      final value = await sessionStorage.read('auth_session');

      check(value).equals('legacy-session');
    });

    test(
      'keeps missing-plugin writes readable when the plugin recovers',
      () async {
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(MissingPluginException());
        when(() => secureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => _signedValue('stale-session'));
        await sessionStorage.write(key: 'auth_session', value: 'new-session');
        expect(await sessionStorage.read('auth_session'), 'new-session');
      },
    );

    for (final error in [
      PlatformException(code: 'storage_blocked'),
      UnsupportedError('HTTPS required'),
      StateError('Browser quota exceeded'),
    ]) {
      test('surfaces write failures of type ${error.runtimeType}', () async {
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(error);
        await expectLater(
          sessionStorage.write(key: 'auth_session', value: 'session'),
          throwsA(isA<StorageFailure>()),
        );
      });
      test('surfaces read failures of type ${error.runtimeType}', () async {
        when(() => secureStorage.read(key: any(named: 'key'))).thenThrow(error);
        await expectLater(
          sessionStorage.read('auth_session'),
          throwsA(isA<StorageFailure>()),
        );
      });
    }

    test(
      'failed deletion cannot resurrect a stored token in this instance',
      () async {
        when(() => secureStorage.delete(key: any(named: 'key')))
            .thenThrow(PlatformException(code: 'delete_failed'));
        when(() => secureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => _signedValue('old-session'));
        await expectLater(
          sessionStorage.delete('auth_session'),
          throwsA(isA<StorageFailure>()),
        );
        expect(await sessionStorage.read('auth_session'), isNull);
      },
    );

    test('successful deletion clears a missing-plugin fallback', () async {
      when(
        () => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(MissingPluginException());
      when(() => secureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      await sessionStorage.write(key: 'auth_session', value: 'session');
      await sessionStorage.delete('auth_session');
      expect(await sessionStorage.read('auth_session'), isNull);
    });

    test('should throw storage failure when digest is invalid', () async {
      when(
        () => secureStorage.read(key: any(named: 'key')),
      ).thenAnswer(
        (_) async => jsonEncode(<String, Object?>{
          'version': 1,
          'payload': 'raw-session',
          'digest': 'invalid',
        }),
      );

      await expectLater(
        () => sessionStorage.read('auth_session'),
        throwsA(isA<StorageFailure>()),
      );
    });
  });
}

String _signedValue(String payload) {
  return jsonEncode(<String, Object?>{
    'version': 1,
    'payload': payload,
    'digest': AppCrypto.hashSha256(payload),
  });
}

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
