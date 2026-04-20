import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Severity tier exposed by [AppLogger]. Mapped 1:1 onto the
/// underlying `logger` package levels and used by [AppLogSink] so
/// integrations (e.g. Sentry) can decide whether the event warrants
/// a capture, a breadcrumb, or to be dropped entirely.
enum AppLogLevel { debug, info, warning, error }

/// Sink that observes every entry going through [AppLogger]. Designed
/// to plug observability backends (Sentry today; OpenTelemetry,
/// Datadog, etc. tomorrow) without touching every call site.
///
/// Implementations MUST be non-throwing: an exception inside the sink
/// CANNOT propagate back into the caller — observability cost should
/// never break business code. See `SentryAppLogSink` for the
/// reference implementation.
// Single-method interface kept on purpose so future sinks (Datadog,
// OpenTelemetry) can implement it without breaking existing callers.
// ignore: one_member_abstracts
abstract interface class AppLogSink {
  void onLog({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
    Object? error,
    StackTrace? stackTrace,
  });
}

abstract final class AppLogger {
  static Level minimumLevel = Level.warning;

  /// Optional pluggable sink that observes every `AppLogger.*` entry.
  /// Production wiring connects `SentryAppLogSink` here (see
  /// `bootstrap.dart`); tests inject fakes. Defaults to `null` so
  /// builds without observability stay zero-cost.
  static AppLogSink? sink;

  static final Logger _logger = Logger(
    filter: _ReleaseLogFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      lineLength: 80,
      noBoxingByDefault: true,
      colors: false,
      printEmojis: false,
    ),
  );

  static void debug(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _logger.d(_composeMessage(message, context));
    _forwardToSink(
      level: AppLogLevel.debug,
      message: message,
      context: context,
    );
  }

  static void configureForRuntime() {
    minimumLevel = kDebugMode ? Level.debug : Level.info;
  }

  static void info(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _logger.i(_composeMessage(message, context));
    _forwardToSink(
      level: AppLogLevel.info,
      message: message,
      context: context,
    );
  }

  static void warning(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(
      _composeMessage(message, context),
      error: error,
      stackTrace: stackTrace,
    );
    _forwardToSink(
      level: AppLogLevel.warning,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      _composeMessage(message, context),
      error: error,
      stackTrace: stackTrace,
    );
    _forwardToSink(
      level: AppLogLevel.error,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Defensive wrapper: any exception thrown by the sink is swallowed
  /// (and printed via the underlying logger as a warning) so observers
  /// never break the business code that emitted the log line.
  static void _forwardToSink({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final activeSink = sink;
    if (activeSink == null) {
      return;
    }
    try {
      activeSink.onLog(
        level: level,
        message: message,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
    } on Object catch (sinkError, sinkStack) {
      _logger.w(
        'AppLogger sink threw — observability event dropped',
        error: sinkError,
        stackTrace: sinkStack,
      );
    }
  }

  static String _composeMessage(
    String message,
    Map<String, Object?> context,
  ) {
    if (context.isEmpty) {
      return message;
    }

    final formattedContext = context.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');

    return '$message | $formattedContext';
  }
}

class _ReleaseLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= AppLogger.minimumLevel.index;
  }
}
