import 'package:checks/checks.dart';
import 'package:colmeia/core/update/appcast_probe_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioAppcastProbeClient', () {
    test('should reject invalid feed URLs', () async {
      final client = DioAppcastProbeClient();

      final result = await client.probe(feedUrl: 'not-a-valid-url');

      check(result.success).isFalse();
      check(result.failureKind).equals(AppcastProbeFailureKind.invalidUrl);
    });

    test('should reject non-https feed URLs', () async {
      final client = DioAppcastProbeClient();

      final result = await client.probe(
        feedUrl: 'http://example.com/appcast.xml',
      );

      check(result.success).isFalse();
      check(result.failureKind).equals(AppcastProbeFailureKind.invalidUrl);
    });

    test('should retry once on transient timeout failures', () async {
      final client = DioAppcastProbeClient(
        dio: Dio()
          ..httpClientAdapter = _RetryTimeoutAdapter(payload: _emptyAppcastShell),
      );

      final result = await client.probe(
        feedUrl: 'https://example.com/appcast.xml',
      );

      check(result.success).isTrue();
      check(result.hasReleases).isFalse();
    });

    test('should accept empty-but-valid sparkle appcast shell', () async {
      final client = DioAppcastProbeClient(
        dio: _dioWithPayload(_emptyAppcastShell),
      );

      final result = await client.probe(
        feedUrl: 'https://example.com/appcast.xml',
      );

      check(result.success).isTrue();
      check(result.hasReleases).isFalse();
    });

    test('should detect release entries in populated appcast', () async {
      final client = DioAppcastProbeClient(
        dio: _dioWithPayload(_appcastWithRelease),
      );

      final result = await client.probe(
        feedUrl: 'https://example.com/appcast.xml',
      );

      check(result.success).isTrue();
      check(result.hasReleases).isTrue();
    });

    test('should fail when payload is not a sparkle appcast shell', () async {
      final client = DioAppcastProbeClient(
        dio: _dioWithPayload('<html><body>not xml feed</body></html>'),
      );

      final result = await client.probe(
        feedUrl: 'https://example.com/appcast.xml',
      );

      check(result.success).isFalse();
      check(result.failureKind).equals(AppcastProbeFailureKind.invalidPayload);
    });

    test('should surface HTTP errors from the feed', () async {
      final client = DioAppcastProbeClient(
        dio: _dioWithPayload('', statusCode: 404),
      );

      final result = await client.probe(
        feedUrl: 'https://example.com/appcast.xml',
      );

      check(result.success).isFalse();
      check(result.failureKind).equals(AppcastProbeFailureKind.httpError);
    });
  });
}

const _emptyAppcastShell = '''
<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>
    <title>Colmeia</title>
    <description>Most recent Windows releases for Colmeia</description>
    <language>pt-BR</language>
  </channel>
</rss>
''';

const _appcastWithRelease = '''
<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>
    <title>Colmeia</title>
    <item>
      <title>Version 1.0.0</title>
      <enclosure url="https://example.com/app.exe"
                 sparkle:version="1.0.0"
                 sparkle:os="windows"
                 length="123"
                 type="application/octet-stream" />
    </item>
  </channel>
</rss>
''';

Dio _dioWithPayload(String payload, {int statusCode = 200}) {
  return Dio()
    ..httpClientAdapter = _StubAdapter(payload: payload, statusCode: statusCode);
}

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.payload, required this.statusCode});

  final String payload;
  final int statusCode;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      payload,
      statusCode,
      headers: <String, List<String>>{
        'content-type': <String>['application/xml'],
      },
    );
  }
}

final class _RetryTimeoutAdapter implements HttpClientAdapter {
  _RetryTimeoutAdapter({required this.payload});

  final String payload;
  var _attempts = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _attempts++;
    if (_attempts == 1) {
      throw DioException.connectionTimeout(
        requestOptions: options,
        timeout: const Duration(seconds: 8),
      );
    }

    return ResponseBody.fromString(
      payload,
      200,
      headers: <String, List<String>>{
        'content-type': <String>['application/xml'],
      },
    );
  }
}
