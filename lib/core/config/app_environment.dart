abstract final class AppEnvironment {
  static const bool useFakeBackend = bool.fromEnvironment(
    'USE_FAKE_BACKEND',
    defaultValue: true,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Project DSN from `--dart-define=SENTRY_DSN=...`. Leave empty to disable
  /// Sentry; never commit production secrets into source.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// When true, initializes Sentry in debug builds if [sentryDsn] is set.
  static const bool sentryDebug = bool.fromEnvironment('SENTRY_DEBUG');

  /// Raw `--dart-define=SENTRY_TRACES_SAMPLE_RATE=` (e.g. `0.2`).
  /// Invalid values fall back to [defaultSentryTracesSampleRate].
  static const String sentryTracesSampleRateRaw = String.fromEnvironment(
    'SENTRY_TRACES_SAMPLE_RATE',
    defaultValue: '0.2',
  );

  static const double defaultSentryTracesSampleRate = 0.2;

  static double get sentryTracesSampleRate {
    final parsed = double.tryParse(sentryTracesSampleRateRaw);
    if (parsed == null || parsed < 0 || parsed > 1) {
      return defaultSentryTracesSampleRate;
    }
    return parsed;
  }
}
