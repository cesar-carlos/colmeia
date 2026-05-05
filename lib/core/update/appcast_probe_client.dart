import 'package:dio/dio.dart';

enum AppcastProbeFailureKind {
  invalidUrl,
  timeout,
  httpError,
  invalidPayload,
  network,
}

class AppcastProbeResult {
  const AppcastProbeResult._({
    required this.success,
    required this.failureKind,
    required this.details,
  });

  const AppcastProbeResult.success()
    : this._(
        success: true,
        failureKind: null,
        details: null,
      );

  const AppcastProbeResult.failure({
    required AppcastProbeFailureKind failureKind,
    String? details,
  }) : this._(
         success: false,
         failureKind: failureKind,
         details: details,
       );

  final bool success;
  final AppcastProbeFailureKind? failureKind;
  final String? details;
}

typedef AppcastProbeClient =
    Future<AppcastProbeResult> Function({required String feedUrl});

final class DioAppcastProbeClient {
  DioAppcastProbeClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 8),
              responseType: ResponseType.plain,
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

  final Dio _dio;

  Future<AppcastProbeResult> probe({required String feedUrl}) async {
    final normalizedFeedUrl = feedUrl.trim();
    final uri = Uri.tryParse(normalizedFeedUrl);
    final normalizedPath = uri?.path.toLowerCase() ?? '';
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !normalizedPath.endsWith('.xml')) {
      return const AppcastProbeResult.failure(
        failureKind: AppcastProbeFailureKind.invalidUrl,
      );
    }

    try {
      final response = await _dio.get<String>(normalizedFeedUrl);
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        return AppcastProbeResult.failure(
          failureKind: AppcastProbeFailureKind.httpError,
          details: 'HTTP $statusCode ao consultar o appcast.',
        );
      }

      final payload = (response.data ?? '').trim();
      if (!_looksLikeSparkleAppcast(payload)) {
        return const AppcastProbeResult.failure(
          failureKind: AppcastProbeFailureKind.invalidPayload,
          details: 'O feed respondeu sem um XML appcast compativel.',
        );
      }

      return const AppcastProbeResult.success();
    } on DioException catch (error) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => const AppcastProbeResult.failure(
          failureKind: AppcastProbeFailureKind.timeout,
          details: 'O feed demorou mais que o esperado para responder.',
        ),
        DioExceptionType.badResponse => AppcastProbeResult.failure(
          failureKind: AppcastProbeFailureKind.httpError,
          details:
              'HTTP ${error.response?.statusCode ?? 'desconhecido'} ao consultar o appcast.',
        ),
        _ => AppcastProbeResult.failure(
          failureKind: AppcastProbeFailureKind.network,
          details: error.message,
        ),
      };
    } on Object catch (error) {
      return AppcastProbeResult.failure(
        failureKind: AppcastProbeFailureKind.network,
        details: error.toString(),
      );
    }
  }

  static bool _looksLikeSparkleAppcast(String payload) {
    if (payload.isEmpty) {
      return false;
    }

    final normalized = payload.toLowerCase();
    return normalized.contains('<rss') &&
        normalized.contains('<channel') &&
        normalized.contains('<item') &&
        normalized.contains('sparkle:version');
  }
}
