import 'package:checks/checks.dart';
import 'package:colmeia/core/security/app_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppCrypto', () {
    test('should generate deterministic sha256 hash', () {
      check(
        AppCrypto.hashSha256('colmeia'),
      ).equals(
        '4a5c0838bb397331a4f27195980b69ecfadc67379cb29f281842e38147b06955',
      );
    });

    test('should combine value and salt for sha256 hashing', () {
      check(
        AppCrypto.hashSha256WithSalt(
          value: 'colmeia',
          salt: 'salt',
        ),
      ).equals(
        '7e05a879dd42f6e1f55c1e5278a7f047e787e91f92dafaf2941cfacf5bc6de6b',
      );
    });

    test('should sign payload with hmac sha256', () {
      check(
        AppCrypto.signHmacSha256(
          value: 'colmeia',
          secret: 'secret-key',
        ),
      ).equals(
        '07115bd5f3a007cb15fae2112897cba60bbab224cde3ef0522105c903f1297e3',
      );
    });

    test('should compare values with constant time semantics', () {
      check(
        AppCrypto.secureEquals(
          'signed-value',
          'signed-value',
        ),
      ).isTrue();
      check(
        AppCrypto.secureEquals(
          'signed-value',
          'tampered-value',
        ),
      ).isFalse();
    });
  });
}
