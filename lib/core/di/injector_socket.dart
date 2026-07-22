import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/config/connection_ready_compat_mode.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/auth_refresh_coordinator.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/observability/socket/socket_channel_metrics.dart';
import 'package:colmeia/core/observability/socket/socket_metrics_listener.dart';
import 'package:colmeia/core/socket/agent_command_batch_coordinator.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/agent_latency_oracle.dart';
import 'package:colmeia/core/socket/agent_sql_cancel_emitter.dart';
import 'package:colmeia/core/socket/app_socket_url_resolver.dart';
import 'package:colmeia/core/socket/connection_ready_payload.dart';
import 'package:colmeia/core/socket/consumer_socket_app_error_codes.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_pool.dart';
import 'package:colmeia/core/socket/direct_agent_command_sender.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/core/socket/payload_frame_signer.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/core/socket/relay/relay_batch_command_coordinator.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/socket_auth_token_provider.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher_impl.dart';
import 'package:colmeia/core/socket/socket_io_client_factory.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
import 'package:get_it/get_it.dart';

/// PR-A: registers the consumer socket infrastructure as **lazy** singletons.
/// Nothing is connected until a consumer (PR-B and beyond) explicitly calls
/// `ConsumerSocketConnection.connect()`. Keeping it lazy means builds with
/// `AGENT_BRIDGE_TRANSPORT=rest` (default) never instantiate the socket
/// stack at startup.
void registerInjectorSocket(GetIt getIt) {
  getIt
    ..registerLazySingleton<SocketAuthTokenProvider>(
      () => SessionSocketAuthTokenProvider(
        sessionAccessor: getIt<AuthSessionAccessor>(),
        refreshCoordinator: getIt<AuthRefreshCoordinator>(),
        sessionEvents: getIt<AuthSessionEvents>(),
      ),
    )
    ..registerLazySingleton<AppSocketUrlResolver>(
      () => AppSocketUrlResolver(
        rawApiBaseUrl: AppEnvironment.apiBaseUrl,
        namespace: AppEnvironment.socketNamespace,
      ),
    )
    ..registerLazySingleton<SocketIoClientFactory>(
      () => const DefaultSocketIoClientFactory(),
    )
    ..registerLazySingleton<ConnectionReadyDecoder>(_buildReadyDecoder)
    // Single PayloadFrameCodec shared across the relay dispatcher and
    // the connection:ready decoder. When `SOCKET_PAYLOAD_SIGNING_KEY`
    // is set we also build a signer so every outbound frame is HMAC'd
    // — the hub validates with `PAYLOAD_SIGNING_KEY`, so the two MUST
    // agree byte-for-byte (UTF-8) for verification to succeed.
    ..registerLazySingleton<PayloadFrameCodec>(_buildPayloadFrameCodec)
    ..registerLazySingleton<ConsumerSocketConnection>(
      () => ConsumerSocketConnection(
        urlResolver: getIt<AppSocketUrlResolver>(),
        tokenProvider: getIt<SocketAuthTokenProvider>(),
        factory: getIt<SocketIoClientFactory>(),
        readyDecoder: getIt<ConnectionReadyDecoder>(),
        handshakeTimeout: Duration(
          milliseconds: AppEnvironment.socketHandshakeTimeoutMs,
        ),
        maxReconnectAttempts: AppEnvironment.socketReconnectAttempts,
        reconnectInitialDelay: Duration(
          milliseconds: AppEnvironment.socketReconnectInitialDelayMs,
        ),
        reconnectMaxDelay: Duration(
          milliseconds: AppEnvironment.socketReconnectMaxDelayMs,
        ),
        onTerminalHubAppError: (code, message) {
          if (!ConsumerSocketAppErrorCodes.requiresAuthSessionInvalidation(
            code,
          )) {
            return;
          }
          if (!getIt.isRegistered<AuthSessionEvents>()) {
            return;
          }
          getIt<AuthSessionEvents>().notifyInvalidated();
        },
      ),
      dispose: (connection) => connection.dispose(),
    )
    ..registerLazySingleton<SocketChannelMetrics>(SocketChannelMetrics.new)
    ..registerLazySingleton<SocketRequestCorrelator>(
      () => SocketRequestCorrelator(
        onOrphanWireResponse:
            ({
              required rpcId,
              required operation,
              required responseFieldCount,
            }) {
              getIt<SocketChannelMetrics>().recordCorrelatorOrphanWire(
                operation: operation,
              );
            },
      ),
      dispose: (correlator) => correlator.dispose(),
    )
    ..registerLazySingleton<SocketCommandDispatcher>(
      () => SocketCommandDispatcherImpl(
        connection: getIt<ConsumerSocketConnection>(),
        correlator: getIt<SocketRequestCorrelator>(),
        concurrencyGate: _resolveConcurrencyGate(getIt),
        latencyOracle: _resolveLatencyOracle(getIt),
        payloadFrameCodec: getIt<PayloadFrameCodec>(),
        defaultTimeout: Duration(
          milliseconds: AppEnvironment.socketRequestTimeoutMs,
        ),
        coalescingEnabled: AppEnvironment.socketCoalescingEnabled,
        onCoalesced: () => getIt<SocketChannelMetrics>().recordCoalesced(),
        onServerTimings: (timings) =>
            getIt<SocketChannelMetrics>().recordServerTimings(timings),
      ),
      dispose: (dispatcher) => dispatcher.dispose(),
    )
    // Direct sender always exists: it is the fallback used either as the
    // bypass target of the batch coordinator or as the standalone sender
    // when batching is disabled.
    ..registerLazySingleton<DirectAgentCommandSender>(
      () => DirectAgentCommandSender(
        dispatcher: getIt<SocketCommandDispatcher>(),
      ),
    );

  // Register the concurrency gate as a non-nullable singleton only when
  // the env ceiling is positive; otherwise the dispatcher receives `null`
  // and dispatches with no per-agent throttling.
  final ceiling = AppEnvironment.socketMaxInflightPerAgent;
  if (ceiling > 0) {
    final waitersCap = AppEnvironment.socketMaxInflightWaitersPerAgent;
    final acquireWaitMs = AppEnvironment.socketMaxInflightAcquireWaitMs;
    getIt.registerLazySingleton<PerAgentConcurrencyGate>(
      () => PerAgentConcurrencyGate(
        maxInflightPerAgent: ceiling,
        maxWaitersPerAgent: waitersCap > 0 ? waitersCap : null,
        maxWaitForSlot: acquireWaitMs > 0
            ? Duration(milliseconds: acquireWaitMs)
            : null,
        onWaiterQueueRejected: () {
          getIt<SocketChannelMetrics>().recordGateWaiterQueueRejected();
        },
        onAcquireWaitTimeout: () {
          getIt<SocketChannelMetrics>().recordGateAcquireWaitTimeout();
        },
      ),
    );
  }

  // Adaptive timeout oracle is opt-in (P2). When disabled neither the
  // dispatcher nor the metrics listener consult it.
  if (AppEnvironment.socketTimeoutAdaptiveEnabled) {
    getIt.registerLazySingleton<AgentLatencyOracle>(AgentLatencyOracle.new);
  }

  // PR-L: relay (relay:*) lives on top of the same ConsumerSocketConnection
  // and is active for socket transport (or explicitly through
  // SOCKET_RELAY_ENABLED). We register both the conversation manager and the
  // dispatcher only when needed so REST builds do not pay for PayloadFrame
  // allocations or extra listeners.
  if (AppEnvironment.socketRelayEnabled &&
      !AppEnvironment.e2eDisableRelayDispatch) {
    getIt
      ..registerLazySingleton<RelayConversationManager>(
        () => RelayConversationManager(
          connection: getIt<ConsumerSocketConnection>(),
          startTimeout: Duration(
            milliseconds: AppEnvironment.socketRelayConversationStartTimeoutMs,
          ),
          endTimeout: Duration(
            milliseconds: AppEnvironment.socketRelayConversationEndTimeoutMs,
          ),
          channelMetrics: getIt<SocketChannelMetrics>(),
        ),
        dispose: (manager) => manager.dispose(),
      )
      ..registerLazySingleton<RelayCommandDispatcherImpl>(
        () => RelayCommandDispatcherImpl(
          connection: getIt<ConsumerSocketConnection>(),
          conversationManager: getIt<RelayConversationManager>(),
          // Reuse the shared codec so signing config (if any) reaches
          // every relay frame without duplicating the wire-up here.
          codec: getIt<PayloadFrameCodec>(),
          defaultTimeout: Duration(
            milliseconds: AppEnvironment.socketRelayRequestTimeoutMs,
          ),
          defaultCompression: AppEnvironment.socketRelayPayloadFrameCompression,
          defaultStreamInitialWindow:
              AppEnvironment.socketRelayStreamInitialWindow,
          defaultStreamRefillThreshold:
              AppEnvironment.socketRelayStreamRefillThreshold,
          concurrencyGate: _resolveConcurrencyGate(getIt),
          channelMetrics: getIt<SocketChannelMetrics>(),
          latencyOracle: _resolveLatencyOracle(getIt),
        ),
        // Concrete impl owns the resources; the public interface below
        // is a thin wrapper that just delegates, so disposing the impl
        // (and not double-disposing through the wrapper) is enough.
        dispose: (dispatcher) => dispatcher.dispose(),
      )
      // Public `RelayCommandDispatcher` is the impl directly, OR wrapped
      // by `RelayBatchCommandCoordinator` when the hub flag is on. The
      // coordinator owns no transport resources of its own — its dispose
      // only drains the local queue, the inner impl is already disposed
      // by the registration above.
      ..registerLazySingleton<RelayCommandDispatcher>(
        () => AppEnvironment.socketRelayBatchEnabled
            ? RelayBatchCommandCoordinator(
                inner: getIt<RelayCommandDispatcherImpl>(),
                onBatchEmission: ({required size, required partialFailure}) =>
                    getIt<SocketChannelMetrics>().recordRelayBatchEmission(
                      size: size,
                      partialFailure: partialFailure,
                    ),
                onBypass: ({required reason}) => getIt<SocketChannelMetrics>()
                    .recordRelayBatchBypass(reason: reason),
              )
            : getIt<RelayCommandDispatcherImpl>(),
      );
  }

  getIt.registerLazySingleton<SocketMetricsListener>(
    () => SocketMetricsListener(
      connection: getIt<ConsumerSocketConnection>(),
      dispatcher: getIt<SocketCommandDispatcher>(),
      metrics: getIt<SocketChannelMetrics>(),
      latencyOracle: _resolveLatencyOracle(getIt),
      relayDispatcher: getIt.isRegistered<RelayCommandDispatcher>()
          ? getIt<RelayCommandDispatcher>()
          : null,
      concurrencyGate: _resolveConcurrencyGate(getIt),
    ),
    dispose: (listener) => listener.dispose(),
  );

  // Pick the active AgentCommandSender. When SOCKET_BATCH_ENABLED=true,
  // the coordinator wraps the direct sender; otherwise the direct sender
  // is registered as the AgentCommandSender directly.
  if (AppEnvironment.socketBatchEnabled) {
    getIt
      ..registerLazySingleton<AgentCommandBatchCoordinator>(
        () => AgentCommandBatchCoordinator(
          directSender: getIt<DirectAgentCommandSender>(),
          windowDuration: Duration(
            milliseconds: AppEnvironment.socketBatchWindowMs,
          ),
          maxBatchSize: AppEnvironment.socketBatchMaxSize,
          minBatchSize: AppEnvironment.socketBatchMinSize,
          defaultTimeout: Duration(
            milliseconds: AppEnvironment.socketRequestTimeoutMs,
          ),
          onBatchEmission: ({required size, required partialFailure}) {
            getIt<SocketChannelMetrics>().recordBatchEmission(
              size: size,
              partialFailure: partialFailure,
            );
          },
          onBypass: ({required reason}) {
            getIt<SocketChannelMetrics>().recordBatchBypass(reason: reason);
          },
        ),
        dispose: (coordinator) => coordinator.dispose(),
      )
      ..registerLazySingleton<AgentCommandSender>(
        () => getIt<AgentCommandBatchCoordinator>(),
      );
  } else {
    getIt.registerLazySingleton<AgentCommandSender>(
      () => getIt<DirectAgentCommandSender>(),
    );
  }

  getIt
    ..registerLazySingleton<ConsumerSocketConnectionPool>(
      () => ConsumerSocketConnectionPool(
        primary: getIt<ConsumerSocketConnection>(),
        poolSize: AppEnvironment.socketConnectionPoolSize,
      ),
    )
    ..registerLazySingleton<AgentSqlCancelEmitter>(
      () => AgentSqlCancelEmitter(sender: getIt<AgentCommandSender>()),
    );
}

PerAgentConcurrencyGate? _resolveConcurrencyGate(GetIt getIt) {
  if (getIt.isRegistered<PerAgentConcurrencyGate>()) {
    return getIt<PerAgentConcurrencyGate>();
  }
  return null;
}

AgentLatencyOracle? _resolveLatencyOracle(GetIt getIt) {
  if (getIt.isRegistered<AgentLatencyOracle>()) {
    return getIt<AgentLatencyOracle>();
  }
  return null;
}

/// Builds the shared [PayloadFrameCodec], wiring an HMAC-SHA256 signer
/// **and** a verifier when `SOCKET_PAYLOAD_SIGNING_KEY` is present.
/// The signer/verifier reuse the hub's wire contract (UTF-8 key +
/// base64 signature value over the `metadata || 0x00 || payload` block)
/// so both ends agree byte-for-byte.
///
/// The verifier is opt-in via `SOCKET_PAYLOAD_REQUIRE_SIGNATURE`:
/// strict mode rejects unsigned frames with `signature_required`,
/// while the default (permissive) tolerates unsigned ones — matching
/// the hub's own opt-in policy controlled by `PAYLOAD_SIGN_OUTBOUND`.
PayloadFrameCodec _buildPayloadFrameCodec() {
  final worker = AppEnvironment.socketPayloadWorkerIsolatesEnabled;
  final gzipDecodeThreshold =
      AppEnvironment.socketPayloadGzipDecodeIsolateThresholdBytes;
  final gzipEncodeThreshold =
      AppEnvironment.socketPayloadGzipEncodeIsolateThresholdBytes;
  final jsonDecodeThreshold =
      AppEnvironment.socketPayloadJsonDecodeIsolateThresholdBytes;

  final key = AppEnvironment.socketPayloadSigningKey;
  final requireSignature = AppEnvironment.socketPayloadRequireSignature;
  if (requireSignature && key.isEmpty) {
    AppLogger.warning(
      'SOCKET_PAYLOAD_REQUIRE_SIGNATURE is true but '
      'SOCKET_PAYLOAD_SIGNING_KEY is empty — strict verification disabled',
      context: const <String, Object?>{
        'component': 'injector_socket',
      },
    );
  }
  if (key.isEmpty) {
    return PayloadFrameCodec(
      workerIsolatesEnabled: worker,
      gzipDecodeIsolateThresholdBytes: gzipDecodeThreshold,
      gzipEncodeIsolateThresholdBytes: gzipEncodeThreshold,
      jsonDecodeIsolateThresholdBytes: jsonDecodeThreshold,
    );
  }
  final keyId = AppEnvironment.socketPayloadSigningKeyId;
  final normalizedKeyId = keyId.isEmpty ? null : keyId;
  return PayloadFrameCodec(
    workerIsolatesEnabled: worker,
    gzipDecodeIsolateThresholdBytes: gzipDecodeThreshold,
    gzipEncodeIsolateThresholdBytes: gzipEncodeThreshold,
    jsonDecodeIsolateThresholdBytes: jsonDecodeThreshold,
    signer: Hmac256PayloadFrameSigner.fromUtf8Key(
      key: key,
      keyId: normalizedKeyId,
    ),
    verifier: Hmac256PayloadFrameSignatureVerifier.fromUtf8Key(
      key: key,
      expectedKeyId: normalizedKeyId,
    ),
    requireSignature: AppEnvironment.socketPayloadRequireSignature,
  );
}

/// PR-K: picks the [ConnectionReadyDecoder] dictated by
/// `SOCKET_CONNECTION_READY_COMPAT_MODE`. Defaults to strict PayloadFrame;
/// use `compat` only as a migration override for older hubs.
ConnectionReadyDecoder _buildReadyDecoder() {
  switch (AppEnvironment.socketConnectionReadyCompatMode) {
    case ConnectionReadyCompatMode.payloadFrameOnly:
      return PayloadFrameConnectionReadyDecoder(
        onParseFailure: _logReadyFrameParseFailure,
      );
    case ConnectionReadyCompatMode.rawJsonOnly:
      return const JsonOnlyConnectionReadyDecoder();
    case ConnectionReadyCompatMode.compat:
      return CompatConnectionReadyDecoder(onShape: _logCompatShape);
  }
}

void _logReadyFrameParseFailure(PayloadFrameParseFailure failure) {
  AppLogger.warning(
    'connection:ready PayloadFrame parse failed',
    context: <String, Object?>{
      'component': 'PayloadFrameConnectionReadyDecoder',
      'code': failure.code,
      'message': failure.message,
    },
  );
}

void _logCompatShape(ConnectionReadyShape shape) {
  AppLogger.debug(
    'connection:ready decoded',
    context: <String, Object?>{
      'component': 'CompatConnectionReadyDecoder',
      'shape': shape.name,
    },
  );
}
