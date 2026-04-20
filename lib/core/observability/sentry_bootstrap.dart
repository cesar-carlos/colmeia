import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/sentry_app_log_sink.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

bool get shouldInitializeSentry {
  if (AppEnvironment.sentryDsn.isEmpty) {
    return false;
  }
  if (kReleaseMode || kProfileMode) {
    return true;
  }
  return AppEnvironment.sentryDebug;
}

String get _sentryEnvironmentName {
  if (kReleaseMode) {
    return 'release';
  }
  if (kProfileMode) {
    return 'profile';
  }
  return 'debug';
}

Future<void> runAppWithOptionalSentry(
  Future<void> Function() appRunner,
) async {
  if (!shouldInitializeSentry) {
    await appRunner();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options
        ..dsn = AppEnvironment.sentryDsn
        ..environment = _sentryEnvironmentName
        ..tracesSampleRate = AppEnvironment.sentryTracesSampleRate
        ..sendDefaultPii = false;
    },
    appRunner: () async {
      // Wire the log sink AFTER `SentryFlutter.init` resolves so the
      // first call to `Sentry.captureException` already has a hub
      // bound. Cleared in `appRunner` exit so a future hot-restart
      // does not retain a stale sink pointing at a closed hub.
      AppLogger.sink = SentryAppLogSink();
      try {
        await appRunner();
      } finally {
        AppLogger.sink = null;
      }
    },
  );
}
