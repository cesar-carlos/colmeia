import 'dart:ui';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Uncaught Flutter framework error',
      context: <String, Object?>{
        'library': details.library,
        'component': 'FlutterError.onError',
      },
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'Uncaught platform error',
      context: const <String, Object?>{
        'component': 'PlatformDispatcher.onError',
      },
      error: error,
      stackTrace: stack,
    );
    return true;
  };
}

void installBrandedErrorWidget() {
  if (kDebugMode) return;

  ErrorWidget.builder = (details) {
    return const ColoredBox(
      color: Color(0xFFF5F5F5),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Algo deu errado.\nReinicie o aplicativo.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF424242),
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  };
}
