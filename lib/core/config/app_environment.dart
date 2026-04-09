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

  /// Non-production credentials for integration / e2e agent SQL runs.
  ///
  /// Prefer `--dart-define=E2E_AGENT_ID=...` and
  /// `--dart-define=E2E_CLIENT_TOKEN=...` in CI; avoid committing real tokens.
  /// Optional `local.env` may set these for local device runs (still bundled —
  /// treat as non-secret test data).
  static String get e2eAgentId => AppEnvironmentResolution.resolveString(
    fromDefine: const String.fromEnvironment(EnvKeys.e2eAgentId),
    fromDotenv: _dotenvMaybe(EnvKeys.e2eAgentId),
    fallback: '',
  );

  /// See [e2eAgentId].
  static String get e2eClientToken => AppEnvironmentResolution.resolveString(
    fromDefine: const String.fromEnvironment(EnvKeys.e2eClientToken),
    fromDotenv: _dotenvMaybe(EnvKeys.e2eClientToken),
    fallback: '',
  );

  /// True when both [e2eAgentId] and [e2eClientToken] are non-empty.
  static bool get hasE2eAgentQueryCredentials =>
      e2eAgentId.isNotEmpty && e2eClientToken.isNotEmpty;

  /// Test user email for client login during integration / e2e.
  static String get e2eClientEmail => AppEnvironmentResolution.resolveString(
    fromDefine: const String.fromEnvironment(EnvKeys.e2eClientEmail),
    fromDotenv: _dotenvMaybe(EnvKeys.e2eClientEmail),
    fallback: '',
  );

  /// Test user password for [e2eClientEmail]. Never commit real passwords.
  static String get e2eClientPassword => AppEnvironmentResolution.resolveString(
    fromDefine: const String.fromEnvironment(EnvKeys.e2eClientPassword),
    fromDotenv: _dotenvMaybe(EnvKeys.e2eClientPassword),
    fallback: '',
  );

  /// True when both login fields are set (HTTP Bearer for `/agents/commands`).
  static bool get hasE2eClientLoginCredentials =>
      e2eClientEmail.isNotEmpty && e2eClientPassword.isNotEmpty;

  /// Agent bridge + client-auth data for a full stack e2e run.
  static bool get hasE2eAgentBridgeCredentials =>
      hasE2eAgentQueryCredentials && hasE2eClientLoginCredentials;

  static String? _dotenvMaybe(String key) {
    if (!dotenv.isInitialized) {
      return null;
    }
    return dotenv.env[key];
  }
}
