import 'package:colmeia/core/logging/app_logger.dart';

class AppLocationResolutionObserver {
  const AppLocationResolutionObserver();

  void onEvent({
    required String event,
    required Map<String, Object?> context,
  }) {}
}

class AppLoggerLocationResolutionObserver
    extends AppLocationResolutionObserver {
  const AppLoggerLocationResolutionObserver();

  @override
  void onEvent({
    required String event,
    required Map<String, Object?> context,
  }) {
    final message = 'location_resolution.$event';
    if (_isWarningEvent(event)) {
      AppLogger.warning(message, context: context);
      return;
    }

    AppLogger.info(message, context: context);
  }

  bool _isWarningEvent(String event) {
    return switch (event) {
      'provider_transient_failure' => true,
      _ => false,
    };
  }
}
