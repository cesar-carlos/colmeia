import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/observability/sentry_android_sdk_level.dart';
import 'package:colmeia/core/observability/sentry_app_log_sink.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

/// Tags the active Sentry scope and records a boot breadcrumb after DI is ready.
Future<void> configureSentryBootScope() async {
  if (!shouldInitializeSentry) {
    return;
  }

  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final platformName = defaultTargetPlatform.name;
    final androidSdkLevel = resolveAndroidSdkApiLevelForSentry();

    await Sentry.configureScope((scope) {
      unawaited(scope.setTag('app_version', packageInfo.version));
      unawaited(scope.setTag('app_build', packageInfo.buildNumber));
      unawaited(scope.setTag('platform', platformName));
      if (androidSdkLevel != null) {
        unawaited(scope.setTag('android_sdk', androidSdkLevel));
      }
    });

    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'Colmeia application boot',
        category: 'bootstrap',
        level: SentryLevel.info,
        data: <String, String>{
          'app_version': packageInfo.version,
          'app_build': packageInfo.buildNumber,
          'platform': platformName,
          'android_sdk': ?androidSdkLevel,
        },
      ),
    );
  } on Object {
    // Observability must never block application boot.
  }
}

/// Initializes Sentry when configured, then runs [appRunner] in the **same**
/// zone as the caller.
///
/// Deliberately omits `SentryFlutter.init`'s `appRunner` parameter: that
/// callback can run in a different zone than `WidgetsFlutterBinding.ensureInitialized`,
/// which triggers Flutter's "Zone mismatch" assertion around `runApp`.
/// Uncaught errors are still covered by [PlatformDispatcher.onError] /
/// `FlutterError.onError` (and Sentry's integrations once init completes).
Future<void> runAppWithOptionalSentry(
  Future<void> Function() appRunner,
) async {
  if (!shouldInitializeSentry) {
    await appRunner();
    return;
  }

  await SentryFlutter.init((options) {
    options
      ..dsn = AppEnvironment.sentryDsn
      ..environment = _sentryEnvironmentName
      ..tracesSampleRate = AppEnvironment.sentryTracesSampleRate
      ..sendDefaultPii = false;
  });

  // Wire the log sink AFTER `SentryFlutter.init` resolves so the first call
  // to `Sentry.captureException` already has a hub bound. Cleared on exit so
  // a future hot-restart does not retain a stale sink pointing at a closed hub.
  AppLogger.sink = SentryAppLogSink();
  try {
    await appRunner();
  } finally {
    AppLogger.sink = null;
  }
}
