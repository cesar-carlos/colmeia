import 'package:colmeia/core/config/app_environment.dart';
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
    appRunner: appRunner,
  );
}
