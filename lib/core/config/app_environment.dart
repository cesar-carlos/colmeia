import 'package:colmeia/core/config/app_environment_resolution.dart';
import 'package:colmeia/core/config/env_keys.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppEnvironment {
  static bool get useFakeBackend => AppEnvironmentResolution.resolveBool(
    fromDefine: const String.fromEnvironment(EnvKeys.useFakeBackend),
    fromDotenv: _dotenvMaybe(EnvKeys.useFakeBackend),
    fallback: false,
  );

  static String get apiBaseUrl => AppEnvironmentResolution.resolveString(
    fromDefine: const String.fromEnvironment(EnvKeys.apiBaseUrl),
    fromDotenv: _dotenvMaybe(EnvKeys.apiBaseUrl),
    fallback: '',
  );

  /// Project DSN from `--dart-define=SENTRY_DSN=...` or dotenv. Leave empty to
  /// disable Sentry; never commit production secrets into source.
  static String get sentryDsn => AppEnvironmentResolution.resolveString(
    fromDefine: const String.fromEnvironment(EnvKeys.sentryDsn),
    fromDotenv: _dotenvMaybe(EnvKeys.sentryDsn),
    fallback: '',
  );

  /// When true, initializes Sentry in debug builds if [sentryDsn] is set.
  static bool get sentryDebug => AppEnvironmentResolution.resolveBool(
    fromDefine: const String.fromEnvironment(EnvKeys.sentryDebug),
    fromDotenv: _dotenvMaybe(EnvKeys.sentryDebug),
    fallback: false,
  );

  /// Raw `SENTRY_TRACES_SAMPLE_RATE` (e.g. `0.2`). Invalid values fall back
  /// via [sentryTracesSampleRate].
  static String get sentryTracesSampleRateRaw =>
      AppEnvironmentResolution.resolveString(
        fromDefine: const String.fromEnvironment(
          EnvKeys.sentryTracesSampleRate,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.sentryTracesSampleRate),
        fallback: '0.2',
      );

  static const double defaultSentryTracesSampleRate = 0.2;

  static double get sentryTracesSampleRate {
    final parsed = double.tryParse(sentryTracesSampleRateRaw);
    if (parsed == null || parsed < 0 || parsed > 1) {
      return defaultSentryTracesSampleRate;
    }
    return parsed;
  }

  static String? _dotenvMaybe(String key) {
    if (!dotenv.isInitialized) {
      return null;
    }
    return dotenv.env[key];
  }
}
