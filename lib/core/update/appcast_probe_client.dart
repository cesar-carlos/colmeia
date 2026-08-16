import 'package:colmeia/core/update/app_auto_update_support.dart';
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
    required this.hasReleases,
  });

  const AppcastProbeResult.success({bool hasReleases = true})
    : this._(
        success: true,
        failureKind: null,
        details: null,
        hasReleases: hasReleases,
      );

  const AppcastProbeResult.failure({
    required AppcastProbeFailureKind failureKind,
    String? details,
  }) : this._(
         success: false,
         failureKind: failureKind,
         details: details,
         hasReleases: false,
       );

  final bool success;
  final AppcastProbeFailureKind? failureKind;
  final String? details;
  final bool hasReleases;
}

typedef AppcastProbeClient = Future<AppcastProbeResult> Function({
  required String feedUrl,
});

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

  static const Duration _retryDelay = Duration(milliseconds: 400);
  static const int _maxAttempts = 2;

  final Dio _dio;

  Future<AppcastProbeResult> probe({required String feedUrl}) async {
    final normalizedFeedUrl = feedUrl.trim();
    if (!AppAutoUpdateSupport.isProbeableFeedUrl(normalizedFeedUrl)) {
      return const AppcastProbeResult.failure(
        failureKind: AppcastProbeFailureKind.invalidUrl,
      );
    }

    AppcastProbeResult? lastResult;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      lastResult = await _probeOnce(normalizedFeedUrl);
      if (lastResult.success || !_shouldRetry(lastResult)) {
        return lastResult;
      }
      if (attempt < _maxAttempts - 1) {
        await Future<void>.delayed(_retryDelay);
      }
    }

    return lastResult!;
  }

  Future<AppcastProbeResult> _probeOnce(String normalizedFeedUrl) async {
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
      if (!_isValidSparkleAppcastShell(payload)) {
        return const AppcastProbeResult.failure(
          failureKind: AppcastProbeFailureKind.invalidPayload,
          details: 'O feed respondeu sem um XML appcast compativel.',
        );
      }

      return AppcastProbeResult.success(
        hasReleases: _hasReleaseEntries(payload),
      );
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
        _ => const AppcastProbeResult.failure(
          failureKind: AppcastProbeFailureKind.network,
          details: 'Nao foi possivel acessar o feed oficial. Verifique sua conexao e tente novamente.',
        ),
      };
    } on Object catch (_) {
      return const AppcastProbeResult.failure(
        failureKind: AppcastProbeFailureKind.network,
        details: 'Nao foi possivel acessar o feed oficial. Verifique sua conexao e tente novamente.',
      );
    }
  }

  static bool _shouldRetry(AppcastProbeResult result) {
    return switch (result.failureKind) {
      AppcastProbeFailureKind.timeout ||
      AppcastProbeFailureKind.network => true,
      AppcastProbeFailureKind.httpError => _isRetryableHttpStatus(
        result.details,
      ),
      _ => false,
    };
  }

  static bool _isRetryableHttpStatus(String? details) {
    if (details == null || details.isEmpty) {
      return false;
    }

    final match = RegExp(r'HTTP (\d+)').firstMatch(details);
    if (match == null) {
      return false;
    }

    final statusCode = int.tryParse(match.group(1) ?? '');
    return statusCode != null && statusCode >= 500;
  }

  static bool _isValidSparkleAppcastShell(String payload) {
    if (payload.isEmpty) {
      return false;
    }

    final normalized = payload.toLowerCase();
    return normalized.contains('<rss') && normalized.contains('<channel');
  }

  static bool _hasReleaseEntries(String payload) {
    final normalized = payload.toLowerCase();
    return normalized.contains('<item') &&
        normalized.contains('sparkle:version');
  }
}
