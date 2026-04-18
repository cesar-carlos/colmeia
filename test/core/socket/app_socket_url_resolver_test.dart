import 'package:checks/checks.dart';
import 'package:colmeia/core/socket/app_socket_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSocketUrlResolver', () {
    test('strips /api/v1 and appends namespace', () {
      final resolver = AppSocketUrlResolver(
        rawApiBaseUrl: 'https://hub.example.com/api/v1',
      );
      check(resolver.consumersUrl).equals('https://hub.example.com/consumers');
      check(resolver.hubOrigin).equals('https://hub.example.com');
      check(resolver.namespace).equals('/consumers');
    });

    test('handles base URL without explicit /api/v1 path', () {
      final resolver = AppSocketUrlResolver(
        rawApiBaseUrl: 'https://hub.example.com',
      );
      // AppDioClient.normalizeBaseUrl turns "" into "/api/v1", which we
      // then strip back to "" — so the result is the namespace at root.
      check(resolver.consumersUrl).equals('https://hub.example.com/consumers');
    });

    test('returns empty string when api base url is blank', () {
      final resolver = AppSocketUrlResolver(rawApiBaseUrl: '');
      check(resolver.consumersUrl).equals('');
      check(resolver.hubOrigin).equals('');
    });

    test('honors overridden namespace', () {
      final resolver = AppSocketUrlResolver(
        rawApiBaseUrl: 'https://hub.example.com/api/v1',
        namespace: '/integration-test',
      );
      check(resolver.consumersUrl)
          .equals('https://hub.example.com/integration-test');
      check(resolver.namespace).equals('/integration-test');
    });

    test('keeps non-default ports', () {
      final resolver = AppSocketUrlResolver(
        rawApiBaseUrl: 'http://localhost:4000/api/v1',
      );
      check(resolver.consumersUrl).equals('http://localhost:4000/consumers');
    });
  });
}
