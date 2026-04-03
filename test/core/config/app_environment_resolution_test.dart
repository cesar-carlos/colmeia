import 'package:checks/checks.dart';
import 'package:colmeia/core/config/app_environment_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironmentResolution.resolveString', () {
    test('should prefer non-empty define over dotenv and fallback', () {
      final r = AppEnvironmentResolution.resolveString(
        fromDefine: 'https://api.example.com',
        fromDotenv: 'https://dot.env',
        fallback: '',
      );
      check(r).equals('https://api.example.com');
    });

    test('should use dotenv when define is empty', () {
      final r = AppEnvironmentResolution.resolveString(
        fromDefine: '',
        fromDotenv: 'https://dot.env',
        fallback: 'fb',
      );
      check(r).equals('https://dot.env');
    });

    test('should treat dotenv empty string as absent', () {
      final r = AppEnvironmentResolution.resolveString(
        fromDefine: '',
        fromDotenv: '',
        fallback: 'fb',
      );
      check(r).equals('fb');
    });

    test('should use fallback when define and dotenv missing', () {
      final r = AppEnvironmentResolution.resolveString(
        fromDefine: '',
        fromDotenv: null,
        fallback: 'fb',
      );
      check(r).equals('fb');
    });
  });

  group('AppEnvironmentResolution.resolveBool', () {
    test('should prefer define when non-empty', () {
      final r = AppEnvironmentResolution.resolveBool(
        fromDefine: 'false',
        fromDotenv: 'true',
        fallback: true,
      );
      check(r).isFalse();
    });

    test('should use dotenv when define empty', () {
      final r = AppEnvironmentResolution.resolveBool(
        fromDefine: '',
        fromDotenv: '1',
        fallback: false,
      );
      check(r).isTrue();
    });

    test('should use fallback when both absent', () {
      final r = AppEnvironmentResolution.resolveBool(
        fromDefine: '',
        fromDotenv: null,
        fallback: true,
      );
      check(r).isTrue();
    });
  });

  group('AppEnvironmentResolution.parseBoolString', () {
    test('should parse true and 1', () {
      check(
        AppEnvironmentResolution.parseBoolString('true', fallback: false),
      ).isTrue();
      check(
        AppEnvironmentResolution.parseBoolString('1', fallback: false),
      ).isTrue();
      check(
        AppEnvironmentResolution.parseBoolString('TRUE', fallback: false),
      ).isTrue();
    });

    test('should parse false and 0', () {
      check(
        AppEnvironmentResolution.parseBoolString('false', fallback: true),
      ).isFalse();
      check(
        AppEnvironmentResolution.parseBoolString('0', fallback: true),
      ).isFalse();
    });

    test('should return fallback on invalid token', () {
      check(
        AppEnvironmentResolution.parseBoolString('maybe', fallback: false),
      ).isFalse();
      check(
        AppEnvironmentResolution.parseBoolString('maybe', fallback: true),
      ).isTrue();
    });
  });
}
