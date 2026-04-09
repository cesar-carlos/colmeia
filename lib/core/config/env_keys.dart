/// Compile-time (`--dart-define`) and dotenv key names used by
/// `AppEnvironment`.
abstract final class EnvKeys {
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String useFakeBackend = 'USE_FAKE_BACKEND';
  static const String sentryDsn = 'SENTRY_DSN';
  static const String sentryDebug = 'SENTRY_DEBUG';
  static const String sentryTracesSampleRate = 'SENTRY_TRACES_SAMPLE_RATE';

  /// Agent UUID for integration / e2e tests that call the real SQL bridge.
  static const String e2eAgentId = 'E2E_AGENT_ID';

  /// Per-agent bridge token (JSON-RPC `client_token`), not the API JWT.
  static const String e2eClientToken = 'E2E_CLIENT_TOKEN';

  /// Client-auth email for e2e (`POST /client-auth/login`).
  static const String e2eClientEmail = 'E2E_CLIENT_EMAIL';

  /// Client-auth password for e2e (use only test accounts; prefer dart-define).
  static const String e2eClientPassword = 'E2E_CLIENT_PASSWORD';
}

/// Asset paths for bundled env files (`loadAppDotenv`).
abstract final class EnvAssetPaths {
  static const String bundledDefault = 'assets/env/default.env';
  static const String bundledLocal = 'assets/env/local.env';
}
