import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/agent_query_transport_policy_mode.dart';
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

  /// Sparkle/WinSparkle appcast XML feed used by the Windows updater.
  /// Prefer `--dart-define=AUTO_UPDATE_FEED_URL=...` for release builds and
  /// keep dotenv empty for local/mobile builds.
  static String get autoUpdateFeedUrl => AppEnvironmentResolution.resolveString(
    fromDefine: const String.fromEnvironment(EnvKeys.autoUpdateFeedUrl),
    fromDotenv: _dotenvMaybe(EnvKeys.autoUpdateFeedUrl),
    fallback: '',
  );

  /// Optional HERE Geocoding & Search API key used for desktop-native
  /// geocoding and as a secondary mobile fallback.
  static String get hereGeocodingApiKey =>
      AppEnvironmentResolution.resolveString(
        fromDefine: const String.fromEnvironment(EnvKeys.hereGeocodingApiKey),
        fromDotenv: _dotenvMaybe(EnvKeys.hereGeocodingApiKey),
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

  /// VM E2E / local harness only: skip relay dispatcher registration
  /// even when [socketRelayEnabled] is true for socket transport, so
  /// the hybrid agent-queries datasource falls back to the base channel for
  /// all `useRelay: true` calls (see bypass log in hybrid datasource). Use when
  /// the hub relay path hangs or is unavailable while still exercising
  /// `agents:command` over `/consumers`.
  static bool get e2eDisableRelayDispatch =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.e2eDisableRelayDispatch,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.e2eDisableRelayDispatch),
        fallback: false,
      );

  static const int defaultAgentSqlCacheMaxSize = 500;
  static const int defaultAgentSqlCacheTtlMs = 3000;
  static const int defaultAgentSqlParseIsolateRowThreshold = 2000;
  static const int defaultAgentSqlCatalogCacheTtlMs = 30000;
  static const int defaultAgentQueryMergeAllConcurrency = 4;
  static const int defaultOverviewTargetWaveConcurrency = 64;
  static const int defaultAgentQueryFactsBucketLoadConcurrency = 1;
  static const int defaultAgentQueryFactsPrefetchDelayMs = 2000;
  static const int defaultAgentQueryTargetResolutionCacheTtlMs = 30000;
  static const int defaultAgentSqlOverviewBatchMaxParallelReadOnlyItems = 4;
  static const bool defaultAgentSqlOverviewMergeSqlBatchesPerTarget = true;
  static const bool defaultAgentQueryFactsBucketUseExecuteBatch = true;
  static const int defaultAgentSqlRelayStreamingMaxConcurrentPerAgent = 4;
  static const int defaultAgentSqlBridgeTimeoutMs = 120000;
  static const int defaultAgentSqlBridgeMediumTimeoutMs = 180000;
  static const int defaultAgentSqlBridgeLongTimeoutMs = 240000;

  static int get agentSqlCacheMaxSize => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.agentSqlCacheMaxSize),
    fromDotenv: _dotenvMaybe(EnvKeys.agentSqlCacheMaxSize),
    fallback: defaultAgentSqlCacheMaxSize,
  ).clamp(1, 5000);

  static int get agentSqlCacheTtlMs => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.agentSqlCacheTtlMs),
    fromDotenv: _dotenvMaybe(EnvKeys.agentSqlCacheTtlMs),
    fallback: defaultAgentSqlCacheTtlMs,
  )._atLeastOrFallback(0, defaultAgentSqlCacheTtlMs);

  static int get agentSqlParseIsolateRowThreshold =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlParseIsolateRowThreshold,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentSqlParseIsolateRowThreshold),
        fallback: defaultAgentSqlParseIsolateRowThreshold,
      ).clamp(0, 100000);

  static int get agentSqlCatalogCacheTtlMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlCatalogCacheTtlMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentSqlCatalogCacheTtlMs),
        fallback: defaultAgentSqlCatalogCacheTtlMs,
      )._atLeastOrFallback(0, defaultAgentSqlCatalogCacheTtlMs);

  /// Parallel mergeAll wave size for across-agent orchestration.
  ///
  /// Tuning guide:
  /// - Default `4` for generic mergeAll surfaces (reports, cadastro, etc.).
  /// - Overview batch loader uses [overviewTargetWaveConcurrency] (default 64),
  ///   independent of this knob.
  /// - Sales live map uses [salesLiveMapMergeWaveSize] (default 64, same as
  ///   overview).
  /// - Hub `-32013` is the JSON-RPC rate-limit family (concurrency, rate window,
  ///   token policy); respect `retry_after_ms` when present.
  static int get agentQueryMergeAllConcurrency =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentQueryMergeAllConcurrency,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentQueryMergeAllConcurrency),
        fallback: defaultAgentQueryMergeAllConcurrency,
      ).clamp(1, 64);

  /// Across-agent wave size for overview SQL batch loads. Defaults to
  /// [defaultOverviewTargetWaveConcurrency] (all agents in one wave when
  /// N <= 64). Explicit `0` mirrors [agentQueryMergeAllConcurrency].
  static int get overviewTargetWaveConcurrency {
    final configured = AppEnvironmentResolution.resolveInt(
      fromDefine: const String.fromEnvironment(
        EnvKeys.overviewTargetWaveConcurrency,
      ),
      fromDotenv: _dotenvMaybe(EnvKeys.overviewTargetWaveConcurrency),
      fallback: defaultOverviewTargetWaveConcurrency,
    );
    if (configured == 0) {
      return agentQueryMergeAllConcurrency;
    }
    return configured.clamp(1, 64);
  }

  /// Parallel closed-bucket loads inside cached agent-query repositories.
  static int get agentQueryFactsBucketLoadConcurrency =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentQueryFactsBucketLoadConcurrency,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentQueryFactsBucketLoadConcurrency),
        fallback: defaultAgentQueryFactsBucketLoadConcurrency,
      ).clamp(1, 16);

  /// When true, cached repos batch missing closed buckets via `executeSqlBatch`.
  static bool get agentQueryFactsBucketUseExecuteBatch =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentQueryFactsBucketUseExecuteBatch,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentQueryFactsBucketUseExecuteBatch),
        fallback: defaultAgentQueryFactsBucketUseExecuteBatch,
      );

  /// Delay before post-overview fact prefetch to avoid overlapping with the
  /// dashboard's own SQL burst. `0` disables the delay.
  static int get agentQueryFactsPrefetchDelayMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentQueryFactsPrefetchDelayMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentQueryFactsPrefetchDelayMs),
        fallback: defaultAgentQueryFactsPrefetchDelayMs,
      )._atLeastOrFallback(0, defaultAgentQueryFactsPrefetchDelayMs);

  static const int defaultOverviewSectionPrefetchDelayMs = 2000;

  /// Delay before post-home chart-section prefetch. `0` disables the delay.
  static int get overviewSectionPrefetchDelayMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.overviewSectionPrefetchDelayMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.overviewSectionPrefetchDelayMs),
        fallback: defaultOverviewSectionPrefetchDelayMs,
      )._atLeastOrFallback(0, defaultOverviewSectionPrefetchDelayMs);

  /// Bridge timeout for sales live map period sales and catalog SQL.
  ///
  /// Falls back to [agentSqlBridgeMediumTimeoutMs] when unset.
  static int get salesLiveMapBridgeTimeoutMs {
    final configured = AppEnvironmentResolution.resolveInt(
      fromDefine: const String.fromEnvironment(
        EnvKeys.salesLiveMapBridgeTimeoutMs,
      ),
      fromDotenv: _dotenvMaybe(EnvKeys.salesLiveMapBridgeTimeoutMs),
      fallback: 0,
    );
    if (configured > 0) {
      return configured._atLeastOrFallback(1, agentSqlBridgeMediumTimeoutMs);
    }
    return agentSqlBridgeMediumTimeoutMs;
  }

  /// Across-agent wave size for sales live map SQL loads. Defaults to
  /// [defaultOverviewTargetWaveConcurrency] (all online agents in one wave when
  /// N <= 64). Explicit `0` mirrors [agentQueryMergeAllConcurrency].
  static int get salesLiveMapMergeWaveSize {
    final configured = AppEnvironmentResolution.resolveInt(
      fromDefine: const String.fromEnvironment(
        EnvKeys.salesLiveMapMergeWaveSize,
      ),
      fromDotenv: _dotenvMaybe(EnvKeys.salesLiveMapMergeWaveSize),
      fallback: defaultOverviewTargetWaveConcurrency,
    );
    if (configured == 0) {
      return agentQueryMergeAllConcurrency;
    }
    return configured.clamp(1, 64);
  }

  static int get agentSqlOverviewBatchMaxParallelReadOnlyItems =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlOverviewBatchMaxParallelReadOnlyItems,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.agentSqlOverviewBatchMaxParallelReadOnlyItems,
        ),
        fallback: defaultAgentSqlOverviewBatchMaxParallelReadOnlyItems,
      )._atLeastOrFallback(
        1,
        defaultAgentSqlOverviewBatchMaxParallelReadOnlyItems,
      );

  static bool get agentSqlOverviewMergeSqlBatchesPerTarget =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlOverviewMergeSqlBatchesPerTarget,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.agentSqlOverviewMergeSqlBatchesPerTarget,
        ),
        fallback: defaultAgentSqlOverviewMergeSqlBatchesPerTarget,
      );

  static bool get agentSqlSalesLiveMapMergeSqlBatchesPerTarget =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlSalesLiveMapMergeSqlBatchesPerTarget,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.agentSqlSalesLiveMapMergeSqlBatchesPerTarget,
        ),
        fallback: false,
      );

  static int get agentSqlRelayStreamingMaxConcurrentPerAgent =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlRelayStreamingMaxConcurrentPerAgent,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.agentSqlRelayStreamingMaxConcurrentPerAgent,
        ),
        fallback: defaultAgentSqlRelayStreamingMaxConcurrentPerAgent,
      )._atLeastOrFallback(
        1,
        defaultAgentSqlRelayStreamingMaxConcurrentPerAgent,
      );

  static int get agentSqlBridgeTimeoutMs => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(
      EnvKeys.agentSqlBridgeTimeoutMs,
    ),
    fromDotenv: _dotenvMaybe(EnvKeys.agentSqlBridgeTimeoutMs),
    fallback: defaultAgentSqlBridgeTimeoutMs,
  )._atLeastOrFallback(1, defaultAgentSqlBridgeTimeoutMs);

  static int get agentSqlBridgeMediumTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlBridgeMediumTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentSqlBridgeMediumTimeoutMs),
        fallback: defaultAgentSqlBridgeMediumTimeoutMs,
      )._atLeastOrFallback(1, defaultAgentSqlBridgeMediumTimeoutMs);

  static int get agentSqlBridgeLongTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlBridgeLongTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentSqlBridgeLongTimeoutMs),
        fallback: defaultAgentSqlBridgeLongTimeoutMs,
      )._atLeastOrFallback(1, defaultAgentSqlBridgeLongTimeoutMs);

  /// `0` disables REST per-agent in-flight limiting. Otherwise caps concurrent
  /// `executeSql` / `executeSqlBatch` per agent id before `POST .../commands`.
  static const int defaultAgentSqlRestMaxInflightPerAgent = 8;

  static int get agentSqlRestMaxInflightPerAgent =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentSqlRestMaxInflightPerAgent,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentSqlRestMaxInflightPerAgent),
        fallback: defaultAgentSqlRestMaxInflightPerAgent,
      ).clamp(0, 64);

  static const bool defaultAgentQueryFactsPrefetchEnabled = true;

  static Duration get agentQueryTargetResolutionCacheTtl {
    final ms = AppEnvironmentResolution.resolveInt(
      fromDefine: const String.fromEnvironment(
        EnvKeys.agentQueryTargetResolutionCacheTtlMs,
      ),
      fromDotenv: _dotenvMaybe(EnvKeys.agentQueryTargetResolutionCacheTtlMs),
      fallback: defaultAgentQueryTargetResolutionCacheTtlMs,
    ).clamp(1000, 300000);
    return Duration(milliseconds: ms);
  }

  static bool get agentQueryFactsPrefetchEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.agentQueryFactsPrefetchEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.agentQueryFactsPrefetchEnabled),
        fallback: defaultAgentQueryFactsPrefetchEnabled,
      );

  /// Agent bridge + client-auth data for a full stack e2e run.
  static bool get hasE2eAgentBridgeCredentials =>
      hasE2eAgentQueryCredentials && hasE2eClientLoginCredentials;

  // ----- Socket channel (PR-A) -----

  /// Active transport for `agent_queries` JSON-RPC dispatch.
  ///
  /// Default `rest`. Setting `AGENT_BRIDGE_TRANSPORT=socket` activates the
  /// new Socket channel once the relevant injectors land in subsequent PRs.
  static String get agentBridgeTransportRaw =>
      AppEnvironmentResolution.resolveString(
        fromDefine: const String.fromEnvironment(EnvKeys.agentBridgeTransport),
        fromDotenv: _dotenvMaybe(EnvKeys.agentBridgeTransport),
        fallback: '',
      );

  static AgentBridgeTransport get agentBridgeTransport =>
      AgentBridgeTransport.parse(agentBridgeTransportRaw);

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
  )._atLeastOrFallback(1, defaultSocketReconnectAttempts);

  static int get socketReconnectInitialDelayMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketReconnectInitialDelayMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketReconnectInitialDelayMs),
        fallback: defaultSocketReconnectInitialDelayMs,
      )._atLeastOrFallback(1, defaultSocketReconnectInitialDelayMs);

  static int get socketReconnectMaxDelayMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketReconnectMaxDelayMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketReconnectMaxDelayMs),
        fallback: defaultSocketReconnectMaxDelayMs,
      )._atLeastOrFallback(1, defaultSocketReconnectMaxDelayMs);

  static int get socketRequestTimeoutMs => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.socketRequestTimeoutMs),
    fromDotenv: _dotenvMaybe(EnvKeys.socketRequestTimeoutMs),
    fallback: defaultSocketRequestTimeoutMs,
  )._atLeastOrFallback(1, defaultSocketRequestTimeoutMs);

  static int get socketHandshakeTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketHandshakeTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketHandshakeTimeoutMs),
        fallback: defaultSocketHandshakeTimeoutMs,
      )._atLeastOrFallback(1, defaultSocketHandshakeTimeoutMs);

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

  /// When [socketMaxInflightPerAgent] is enabled, limits how many extra
  /// `acquire` calls may wait per agent. `0` keeps the legacy unbounded
  /// waiter queue.
  static const int defaultSocketMaxInflightWaitersPerAgent = 0;

  static int get socketMaxInflightWaitersPerAgent =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketMaxInflightWaitersPerAgent,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketMaxInflightWaitersPerAgent),
        fallback: defaultSocketMaxInflightWaitersPerAgent,
      );

  /// Max milliseconds a caller may wait in the gate queue. `0` = unlimited.
  static const int defaultSocketMaxInflightAcquireWaitMs = 0;

  static int get socketMaxInflightAcquireWaitMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketMaxInflightAcquireWaitMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketMaxInflightAcquireWaitMs),
        fallback: defaultSocketMaxInflightAcquireWaitMs,
      );

  /// Row cap for streaming SQL collector materialisation. `0` = unlimited.
  static const int defaultSocketStreamSqlCollectorMaxBufferedRows = 0;

  static int get socketStreamSqlCollectorMaxBufferedRows =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketStreamSqlCollectorMaxBufferedRows,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.socketStreamSqlCollectorMaxBufferedRows,
        ),
        fallback: defaultSocketStreamSqlCollectorMaxBufferedRows,
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
  /// `true`; set `false` to use fixed bridge timeouts (review §5.3).
  static bool get socketTimeoutAdaptiveEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketTimeoutAdaptiveEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketTimeoutAdaptiveEnabled),
        fallback: true,
      );

  /// Whether to wire the agent-queries datasource through
  /// `AgentCommandBatchCoordinator` (PR-I, review §5.2). Default `true`;
  /// set `false` to disable JSON-RPC batch coalescing on the socket path.
  static bool get socketBatchEnabled => AppEnvironmentResolution.resolveBool(
    fromDefine: const String.fromEnvironment(EnvKeys.socketBatchEnabled),
    fromDotenv: _dotenvMaybe(EnvKeys.socketBatchEnabled),
    fallback: true,
  );

  static const int defaultSocketBatchWindowMs = 8;
  static const int defaultSocketBatchMaxSize = 32;
  static const int defaultSocketBatchMinSize = 1;

  static int get socketBatchWindowMs => AppEnvironmentResolution.resolveInt(
    fromDefine: const String.fromEnvironment(EnvKeys.socketBatchWindowMs),
    fromDotenv: _dotenvMaybe(EnvKeys.socketBatchWindowMs),
    fallback: defaultSocketBatchWindowMs,
  )._atLeastOrFallback(0, defaultSocketBatchWindowMs);

  static int get socketBatchMaxSize =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(EnvKeys.socketBatchMaxSize),
        fromDotenv: _dotenvMaybe(EnvKeys.socketBatchMaxSize),
        fallback: defaultSocketBatchMaxSize,
      )._clampOrFallback(
        min: 1,
        max: 32,
        fallback: defaultSocketBatchMaxSize,
      );

  static int get socketBatchMinSize {
    final maxSize = socketBatchMaxSize;
    return AppEnvironmentResolution.resolveInt(
      fromDefine: const String.fromEnvironment(EnvKeys.socketBatchMinSize),
      fromDotenv: _dotenvMaybe(EnvKeys.socketBatchMinSize),
      fallback: defaultSocketBatchMinSize,
    )._clampOrFallback(
      min: 1,
      max: maxSize,
      fallback: defaultSocketBatchMinSize.clamp(1, maxSize),
    );
  }

  // ----- Socket channel (PR-L) -----

  /// Whether to register the relay-aware datasource. Socket transport implies
  /// relay availability so `AGENT_BRIDGE_TRANSPORT=socket` is the only switch
  /// needed for the full bridge stack; the env flag still enables relay for
  /// targeted experiments when the primary transport remains REST.
  static bool get socketRelayEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(EnvKeys.socketRelayEnabled),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayEnabled),
        fallback: false,
      ) ||
      agentBridgeTransport == AgentBridgeTransport.socket;

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
      )._atLeastOrFallback(1, defaultSocketRelayRequestTimeoutMs);

  static int get socketRelayConversationStartTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayConversationStartTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayConversationStartTimeoutMs),
        fallback: defaultSocketRelayConversationStartTimeoutMs,
      )._atLeastOrFallback(1, defaultSocketRelayConversationStartTimeoutMs);

  static int get socketRelayConversationEndTimeoutMs =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayConversationEndTimeoutMs,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayConversationEndTimeoutMs),
        fallback: defaultSocketRelayConversationEndTimeoutMs,
      )._atLeastOrFallback(1, defaultSocketRelayConversationEndTimeoutMs);

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
      )._atLeastOrFallback(1, defaultSocketRelayStreamInitialWindow);

  static int get socketRelayStreamRefillThreshold {
    final initialWindow = socketRelayStreamInitialWindow;
    return AppEnvironmentResolution.resolveInt(
      fromDefine: const String.fromEnvironment(
        EnvKeys.socketRelayStreamRefillThreshold,
      ),
      fromDotenv: _dotenvMaybe(EnvKeys.socketRelayStreamRefillThreshold),
      fallback: defaultSocketRelayStreamRefillThreshold,
    )._clampOrFallback(
      min: 0,
      max: initialWindow,
      fallback: defaultSocketRelayStreamRefillThreshold.clamp(0, initialWindow),
    );
  }

  /// Relay JSON-RPC batch arrays (`relay:rpc.request.batch`). Hub v1 shipped
  /// 2026-05-28; bundled [default.env] sets `true` (code fallback `false` when
  /// dotenv/define absent). Distinct from [socketBatchEnabled]
  /// (`agents:command` only). See `docs/bridge_agent_sql_api_options.md`.
  static bool get socketRelayBatchEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayBatchEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayBatchEnabled),
        fallback: false,
      );

  /// Hub opt-in: relay unary fast-path. See
  /// `docs/server_adjustments/relay_unary_fast_path.md`.
  static bool get socketRelayFastPathEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRelayFastPathEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRelayFastPathEnabled),
        fallback: false,
      );

  /// Hub opt-in: per-phase server-side timings on responses. See
  /// `docs/server_adjustments/server_side_phase_diagnostics.md`.
  static bool get socketRequestServerTimingsEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketRequestServerTimingsEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketRequestServerTimingsEnabled),
        fallback: false,
      );

  /// Experimental socket pool size (1 = single connection). Default 1.
  static int get socketConnectionPoolSize =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketConnectionPoolSize,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketConnectionPoolSize),
        fallback: 1,
      ).clamp(1, 4);

  /// Agent SQL transport routing policy env value.
  static AgentQueryTransportPolicyMode get agentQueryTransportPolicyMode =>
      parseAgentQueryTransportPolicyMode(
        AppEnvironmentResolution.resolveString(
          fromDefine: const String.fromEnvironment(
            EnvKeys.agentQueryTransportPolicy,
          ),
          fromDotenv: _dotenvMaybe(EnvKeys.agentQueryTransportPolicy),
          fallback: 'legacy',
        ),
      );

  // ----- Socket presence (PR-M) -----

  /// Whether to register the realtime presence stack
  /// (`SocketAgentPresenceStream` + `ObserveAgentPresenceUseCase`). Socket
  /// transport implies presence so a socket build gets the complete realtime
  /// bridge stack with a single parameter.
  static bool get socketPresenceListenerEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPresenceListenerEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketPresenceListenerEnabled),
        fallback: false,
      ) ||
      agentBridgeTransport == AgentBridgeTransport.socket;

  /// Legacy profile update compatibility. Current hub builds emit
  /// `client:agent.profile.updated` as PayloadFrame; raw JSON maps must be
  /// enabled explicitly only for older hubs.
  static bool get socketProfileUpdatedLegacyRawJsonEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketProfileUpdatedLegacyRawJsonEnabled,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.socketProfileUpdatedLegacyRawJsonEnabled,
        ),
        fallback: false,
      );

  /// True when the app must materialise and lifecycle-manage the consumer
  /// socket, even if the primary bridge transport remains REST.
  static bool get consumerSocketLifecycleEnabled =>
      socketRelayEnabled || socketPresenceListenerEnabled;

  // ----- Socket channel (PR-K) -----

  /// Decoder strategy for `connection:ready`. Defaults to
  /// [ConnectionReadyCompatMode.payloadFrameOnly], matching the current hub
  /// contract. Set `compat` explicitly for older hubs that still emit raw JSON.
  static ConnectionReadyCompatMode get socketConnectionReadyCompatMode =>
      ConnectionReadyCompatMode.parse(
        AppEnvironmentResolution.resolveString(
          fromDefine: const String.fromEnvironment(
            EnvKeys.socketConnectionReadyCompatMode,
          ),
          fromDotenv: _dotenvMaybe(EnvKeys.socketConnectionReadyCompatMode),
          fallback: 'payload_frame_only',
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

  static bool get socketPayloadWorkerIsolatesEnabled =>
      AppEnvironmentResolution.resolveBool(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPayloadWorkerIsolatesEnabled,
        ),
        fromDotenv: _dotenvMaybe(EnvKeys.socketPayloadWorkerIsolatesEnabled),
        fallback: true,
      );

  static int get socketPayloadGzipDecodeIsolateThresholdBytes =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPayloadGzipDecodeIsolateThresholdBytes,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.socketPayloadGzipDecodeIsolateThresholdBytes,
        ),
        fallback: 16 * 1024,
      );

  static const int defaultSocketPayloadGzipEncodeIsolateThresholdBytes =
      64 * 1024;

  static int get socketPayloadGzipEncodeIsolateThresholdBytes =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPayloadGzipEncodeIsolateThresholdBytes,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.socketPayloadGzipEncodeIsolateThresholdBytes,
        ),
        fallback: defaultSocketPayloadGzipEncodeIsolateThresholdBytes,
      );

  static const int defaultSocketPayloadJsonDecodeIsolateThresholdBytes =
      256 * 1024;

  static int get socketPayloadJsonDecodeIsolateThresholdBytes =>
      AppEnvironmentResolution.resolveInt(
        fromDefine: const String.fromEnvironment(
          EnvKeys.socketPayloadJsonDecodeIsolateThresholdBytes,
        ),
        fromDotenv: _dotenvMaybe(
          EnvKeys.socketPayloadJsonDecodeIsolateThresholdBytes,
        ),
        fallback: defaultSocketPayloadJsonDecodeIsolateThresholdBytes,
      );

  static String? _dotenvMaybe(String key) {
    if (!dotenv.isInitialized) {
      return null;
    }
    return dotenv.env[key];
  }
}

extension _ResolvedEnvInt on int {
  int _atLeastOrFallback(int min, int fallback) {
    return this < min ? fallback : this;
  }

  int _clampOrFallback({
    required int min,
    required int max,
    required int fallback,
  }) {
    if (this < min) {
      return fallback;
    }
    if (this > max) {
      return max;
    }
    return this;
  }
}
