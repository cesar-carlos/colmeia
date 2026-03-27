import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

abstract final class AppLogger {
  static Level minimumLevel = Level.warning;

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
  }

  static void configureForRuntime() {
    minimumLevel = kDebugMode ? Level.debug : Level.info;
  }

  static void info(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _logger.i(_composeMessage(message, context));
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
