import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_environment_resolution.dart';
import 'package:colmeia/core/config/connection_ready_compat_mode.dart';
import 'package:colmeia/core/config/env_keys.dart';
import 'package:colmeia/core/socket/relay/relay_event_names.dart';
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

  // ----- Socket channel (PR-A) -----

  /// Active transport for `agent_queries` JSON-RPC dispatch.
  ///
  /// Default `rest`. Setting `AGENT_BRIDGE_TRANSPORT=socket` activates the
  /// new Socket channel once the relevant injectors land in subsequent PRs.
  static AgentBridgeTransport get agentBridgeTransport =>
      AgentBridgeTransport.parse(
        AppEnvironmentResolution.resolveString(
          fromDefine: const String.fromEnvironment(
            EnvKeys.agentBridgeTransport,
          ),
          fromDotenv: _dotenvMaybe(EnvKeys.agentBridgeTransport),
          fallback: 'rest',
        ),
      );

  /// Override for the consumer namespace. Defaults to `/consumers`.
  static String get socketNamespace => AppEnvironmentResolution.resolveString(
    fromDefine: const String.fromEnvironment(EnvKeys.socketNamespace),
    fromDotenv: _dotenvMaybe(EnvKeys.socketNamespace),
    fallback: '/consumers',
  );

  static const int defaultSocketReconnectAttempts = 5;
  static const int defaultSocketReconnectInitialDelayMs = 1000;
  static const int defaultSocketReconnectMaxDelayMs = 30000;
  static const int defaultSocketRequestTimeoutMs = 15000;
  static const int defaultSocketHandshakeTimeoutMs = 10000;

  static int get socketReconnectAttempts => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.socketReconnectAttempts),
    fromDotenv: _dotenvMaybe(EnvKeys.socketReconnectAttempts),
    fallback: defaultSocketReconnectAttempts,
  );

  static int get socketReconnectInitialDelayMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketReconnectInitialDelayMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketReconnectInitialDelayMs),
        fallback: defaultSocketReconnectInitialDelayMs,
      );

  static int get socketReconnectMaxDelayMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketReconnectMaxDelayMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketReconnectMaxDelayMs),
        fallback: defaultSocketReconnectMaxDelayMs,
      );

  static int get socketRequestTimeoutMs => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.socketRequestTimeoutMs),
    fromDotenv: _dotenvMaybe(EnvKeys.socketRequestTimeoutMs),
    fallback: defaultSocketRequestTimeoutMs,
  );

  static int get socketHandshakeTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketHandshakeTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketHandshakeTimeoutMs),
        fallback: defaultSocketHandshakeTimeoutMs,
      );

  /// Whether to pre-connect the consumer socket right after a successful
  /// login. Only effective when [agentBridgeTransport] is
  /// [AgentBridgeTransport.socket]; the lifecycle observer reads both flags.
  static bool get socketWarmUpAfterLogin =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketWarmUpAfterLogin,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketWarmUpAfterLogin),
        fallback: true,
      );

  /// Default ceiling for `PerAgentConcurrencyGate`. `0` disables the gate.
  static const int defaultSocketMaxInflightPerAgent = 8;

  static int get socketMaxInflightPerAgent =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketMaxInflightPerAgent,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketMaxInflightPerAgent),
        fallback: defaultSocketMaxInflightPerAgent,
      );

  /// Whether the dispatcher should coalesce concurrent identical requests
  /// (review §5.1, P1). Default `true`; set `false` as a kill switch.
  static bool get socketCoalescingEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketCoalescingEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketCoalescingEnabled),
        fallback: true,
      );

  /// Activates `AgentLatencyOracle` and routes its timeout suggestions
  /// into the dispatcher when callers do not pass `timeout`. Default
  /// `false` (opt-in); review §5.3 (P2).
  static bool get socketTimeoutAdaptiveEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketTimeoutAdaptiveEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketTimeoutAdaptiveEnabled),
        fallback: false,
      );

  /// Whether to wire the agent-queries datasource through
  /// `AgentCommandBatchCoordinator` (PR-I, review §5.2). Default `false`
  /// (opt-in until baseline metrics validate the savings).
  static bool get socketBatchEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(EnvKeys.socketBatchEnabled),
        fromDotenv: _dotenvMaybe(EnvKeys.socketBatchEnabled),
        fallback: false,
      );

  static const int defaultSocketBatchWindowMs = 8;
  static const int defaultSocketBatchMaxSize = 32;
  static const int defaultSocketBatchMinSize = 1;

  static int get socketBatchWindowMs => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.socketBatchWindowMs),
    fromDotenv: _dotenvMaybe(EnvKeys.socketBatchWindowMs),
    fallback: defaultSocketBatchWindowMs,
  );

  static int get socketBatchMaxSize => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.socketBatchMaxSize),
    fromDotenv: _dotenvMaybe(EnvKeys.socketBatchMaxSize),
    fallback: defaultSocketBatchMaxSize,
  );

  static int get socketBatchMinSize => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.socketBatchMinSize),
    fromDotenv: _dotenvMaybe(EnvKeys.socketBatchMinSize),
    fallback: defaultSocketBatchMinSize,
  );

  // ----- Socket channel (PR-L) -----

  /// Whether to register the relay-aware datasource. When `false` the
  /// agent-queries DI keeps the legacy `agents:command` path only.
  static bool get socketRelayEnabled => AppEnvironmentResolution.resolveBool(
    fromDefine: const String.fromEnvironment(EnvKeys.socketRelayEnabled),
    fromDotenv: _dotenvMaybe(EnvKeys.socketRelayEnabled),
    fallback: false,
  );

  static const int defaultSocketRelayRequestTimeoutMs = 30000;
  static const int defaultSocketRelayConversationStartTimeoutMs = 10000;
  static const int defaultSocketRelayConversationEndTimeoutMs = 5000;

  static int get socketRelayRequestTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayRequestTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayRequestTimeoutMs),
        fallback: defaultSocketRelayRequestTimeoutMs,
      );

  static int get socketRelayConversationStartTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayConversationStartTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayConversationStartTimeoutMs),
        fallback: defaultSocketRelayConversationStartTimeoutMs,
      );

  static int get socketRelayConversationEndTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayConversationEndTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayConversationEndTimeoutMs),
        fallback: defaultSocketRelayConversationEndTimeoutMs,
      );

  static RelayPayloadFrameCompression get socketRelayPayloadFrameCompression =>
      RelayPayloadFrameCompression.parse(
        AppEnvironmentResolution.resolveString(
          fromDefine: const String.fromEnvironment(
            EnvKeys.socketRelayPayloadFrameCompression,
          ),
          fromDotenv: _dotenvMaybe(EnvKeys.socketRelayPayloadFrameCompression),
          fallback: 'default',
        ),
      );

  static const int defaultSocketRelayStreamInitialWindow = 32;
  static const int defaultSocketRelayStreamRefillThreshold = 16;

  static int get socketRelayStreamInitialWindow =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayStreamInitialWindow,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayStreamInitialWindow),
        fallback: defaultSocketRelayStreamInitialWindow,
      );

  static int get socketRelayStreamRefillThreshold =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayStreamRefillThreshold,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayStreamRefillThreshold),
        fallback: defaultSocketRelayStreamRefillThreshold,
      );

  // ----- Socket presence (PR-M) -----

  /// Whether to register the realtime presence stack
  /// (`SocketAgentPresenceStream` + `ObserveAgentPresenceUseCase`).
  /// Default `false` (opt-in).
  static bool get socketPresenceListenerEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPresenceListenerEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketPresenceListenerEnabled),
        fallback: false,
      );

  // ----- Socket channel (PR-K) -----

  /// Decoder strategy for `connection:ready`. Defaults to
  /// [ConnectionReadyCompatMode.compat] so the app keeps working against
  /// hub builds that still emit raw JSON during the migration window.
  static ConnectionReadyCompatMode get socketConnectionReadyCompatMode =>
      ConnectionReadyCompatMode.parse(
        AppEnvironmentResolution.resolveString(
          fromDefine: const String.fromEnvironment(
            EnvKeys.socketConnectionReadyCompatMode,
          ),
          fromDotenv: _dotenvMaybe(EnvKeys.socketConnectionReadyCompatMode),
          fallback: 'compat',
        ),
      );

  // ----- PayloadFrame signing (outbound) -----

  /// Shared HMAC-SHA256 key used by the codec to sign every outbound
  /// frame. Empty (default) → no signing, which mirrors the hub's
  /// "no `PAYLOAD_SIGNING_KEY`" mode. When non-empty, the codec injects
  /// a `signature` block that the hub validates against
  /// `PAYLOAD_SIGNING_KEY` (and optionally enforces
  /// `signature.key_id == PAYLOAD_SIGNING_KEY_ID`).
  static String get socketPayloadSigningKey =>
      AppEnvironmentResolution.resolveString(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPayloadSigningKey,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketPayloadSigningKey),
        fallback: '',
      );

  /// Optional id propagated as `signature.key_id`. Required when the
  /// hub itself is configured with `PAYLOAD_SIGNING_KEY_ID` — otherwise
  /// frames are rejected with `-32001 invalid_signature`. Leave empty
  /// for single-key deployments.
  static String get socketPayloadSigningKeyId =>
      AppEnvironmentResolution.resolveString(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPayloadSigningKeyId,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketPayloadSigningKeyId),
        fallback: '',
      );

  /// Strict inbound mode: when `true` and a signing key is configured,
  /// the codec rejects unsigned frames with `signature_required`.
  /// Default `false` because the hub today emits signed frames only
  /// when itself running with `PAYLOAD_SIGN_OUTBOUND=true`.
  static bool get socketPayloadRequireSignature =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPayloadRequireSignature,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketPayloadRequireSignature),
        fallback: false,
      );

  static String? _dotenvMaybe(String key) {
    if (!dotenv.isInitialized) {
      return null;
    }
    return dotenv.env[key];
  }
}
