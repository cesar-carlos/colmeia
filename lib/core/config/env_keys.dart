/// Compile-time (`--dart-define`) and dotenv key names used by
/// `AppEnvironment`.
abstract final class EnvKeys {
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String useFakeBackend = 'USE_FAKE_BACKEND';
  static const String sentryDsn = 'SENTRY_DSN';
  static const String sentryDebug = 'SENTRY_DEBUG';
  static const String sentryTracesSampleRate = 'SENTRY_TRACES_SAMPLE_RATE';
}

/// Asset paths for bundled env files (`loadAppDotenv`).
abstract final class EnvAssetPaths {
  static const String bundledDefault = 'assets/env/default.env';
  static const String bundledLocal = 'assets/env/local.env';
}
