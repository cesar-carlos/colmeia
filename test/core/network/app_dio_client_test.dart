import 'package:checks/checks.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDioClient.normalizeBaseUrl', () {
    test('should append api namespace when base URL has no path', () {
      final normalized = AppDioClient.normalizeBaseUrl(
        'https://plug-server.se7esistemassinop.com.br',
      );

      check(normalized).equals(
        'https://plug-server.se7esistemassinop.com.br/api/v1',
      );
    });

    test('should append api namespace when base URL ends with slash', () {
      final normalized = AppDioClient.normalizeBaseUrl(
        'https://plug-server.se7esistemassinop.com.br/',
      );

      check(normalized).equals(
        'https://plug-server.se7esistemassinop.com.br/api/v1',
      );
    });

    test('should preserve explicit api namespace path', () {
      final normalized = AppDioClient.normalizeBaseUrl(
        'https://plug-server.se7esistemassinop.com.br/api/v1',
      );

      check(normalized).equals(
        'https://plug-server.se7esistemassinop.com.br/api/v1',
      );
    });

    test('should trim trailing slash from explicit path', () {
      final normalized = AppDioClient.normalizeBaseUrl(
        'https://plug-server.se7esistemassinop.com.br/api/v1/',
      );

      check(normalized).equals(
        'https://plug-server.se7esistemassinop.com.br/api/v1',
      );
    });

    test('should return empty string when input is empty', () {
      check(AppDioClient.normalizeBaseUrl('')).equals('');
    });
  });
}
