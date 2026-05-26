import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

/// Reads a stale cache when the remote call fails. Receives the
/// resolved [DioException] (or `null` for non-Dio errors) so the
/// implementation can decide whether to fall back at all (e.g. skip
/// the cache when the failure is 401/403 to avoid hiding a logout).
///
/// Returning `null` from the callback means "no usable cache, surface
/// the failure".
typedef CacheFallbackReader<T> = Future<T?> Function(DioException? cause);

/// Wraps a remote call so every repository method follows the same
/// `try → map → fallback` shape instead of repeating 3 catch blocks +
/// fallback logic per method.
///
/// Flow:
///
/// 1. Awaits [action]; on success returns `Success(action())`.
/// 2. On error, if [cacheFallback] is provided, asks it for a cached
///    value. The fallback may inspect the underlying [DioException]
///    (or receive `null` for non-Dio errors) and choose to skip itself
///    — e.g. for HTTP 401/403 it usually returns `null` so the user
///    sees a clear "session expired" instead of stale data.
/// 3. If no fallback yields a value, maps the error to [AppFailure]
///    using [mapToAppFailure] with the supplied [fallbackMessage] /
///    [fallbackUserMessage] / [context].
///
/// The handler always returns `AppResult<T>` so callers do not need
/// to declare the type argument twice.
Future<AppResult<T>> withRepositoryErrorMapping<T extends Object>({
  required Future<T> Function() action,
  required String fallbackMessage,
  required String fallbackUserMessage,
  required Map<String, Object?> context,
  CacheFallbackReader<T>? cacheFallback,
}) async {
  try {
    final value = await action();
    return Success<T, AppFailure>(value);
  } on DioException catch (error, stackTrace) {
    if (cacheFallback != null && !isDioUnauthorizedOrForbidden(error)) {
      final cached = await cacheFallback(error);
      if (cached != null) {
        return Success<T, AppFailure>(cached);
      }
    }
    return Failure<T, AppFailure>(
      mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: fallbackMessage,
        fallbackUserMessage: fallbackUserMessage,
        context: context,
      ),
    );
  } on Object catch (error, stackTrace) {
    // Defensive: if the underlying network layer ever rewraps a Dio
    // 401/403 inside another exception type, treat it the same as the
    // direct DioException case so we never accidentally serve stale
    // cache after a session lost auth.
    final dioCause = _resolveDioCause(error);
    if (cacheFallback != null &&
        (dioCause == null || !isDioUnauthorizedOrForbidden(dioCause))) {
      final cached = await cacheFallback(dioCause);
      if (cached != null) {
        return Success<T, AppFailure>(cached);
      }
    }
    return Failure<T, AppFailure>(
      mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: fallbackMessage,
        fallbackUserMessage: fallbackUserMessage,
        context: context,
      ),
    );
  }
}

/// Convenience overload for callers without a cache fallback path:
/// just wraps `try / catch / mapToAppFailure` in a single expression.
Future<AppResult<T>> withRepositoryErrorMappingNoCache<T extends Object>({
  required Future<T> Function() action,
  required String fallbackMessage,
  required String fallbackUserMessage,
  required Map<String, Object?> context,
}) {
  return withRepositoryErrorMapping<T>(
    action: action,
    fallbackMessage: fallbackMessage,
    fallbackUserMessage: fallbackUserMessage,
    context: context,
  );
}

DioException? _resolveDioCause(Object error) {
  if (error is DioException) {
    return error;
  }
  if (error is AppFailure) {
    final cause = error.cause;
    if (cause is DioException) {
      return cause;
    }
  }
  return null;
}
