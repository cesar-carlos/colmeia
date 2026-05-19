import 'package:colmeia/app/router/app_shell_route_observer.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:flutter/material.dart';

abstract final class AppAutoRefreshSupport {
  static RouteObserver<ModalRoute<void>> get routeObserver =>
      appShellRouteObserver;

  static void logInfo(String message, Map<String, Object?> context) {
    AppLogger.info(message, context: context);
  }

  static void logWarning(String message, Map<String, Object?> context) {
    AppLogger.warning(message, context: context);
  }
}
