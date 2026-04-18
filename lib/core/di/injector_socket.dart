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
import 'package:colmeia/core/socket/app_socket_url_resolver.dart';
import 'package:colmeia/core/socket/connection_ready_payload.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/direct_agent_command_sender.dart';
import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
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
      ),
      dispose: (connection) => connection.dispose(),
    )
    ..registerLazySingleton<SocketRequestCorrelator>(
      SocketRequestCorrelator.new,
      dispose: (correlator) => correlator.dispose(),
    )
    ..registerLazySingleton<SocketCommandDispatcher>(
      () => SocketCommandDispatcherImpl(
        connection: getIt<ConsumerSocketConnection>(),
        correlator: getIt<SocketRequestCorrelator>(),
        concurrencyGate: _resolveConcurrencyGate(getIt),
        latencyOracle: _resolveLatencyOracle(getIt),
        defaultTimeout: Duration(
          milliseconds: AppEnvironment.socketRequestTimeoutMs,
        ),
        coalescingEnabled: AppEnvironment.socketCoalescingEnabled,
        onCoalesced: () => getIt<SocketChannelMetrics>().recordCoalesced(),
      ),
      dispose: (dispatcher) => dispatcher.dispose(),
    )
    ..registerLazySingleton<SocketChannelMetrics>(SocketChannelMetrics.new)
    ..registerLazySingleton<SocketMetricsListener>(
      () => SocketMetricsListener(
        connection: getIt<ConsumerSocketConnection>(),
        dispatcher: getIt<SocketCommandDispatcher>(),
        metrics: getIt<SocketChannelMetrics>(),
        latencyOracle: _resolveLatencyOracle(getIt),
      ),
      dispose: (listener) => listener.dispose(),
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
    getIt.registerLazySingleton<PerAgentConcurrencyGate>(
      () => PerAgentConcurrencyGate(maxInflightPerAgent: ceiling),
    );
  }

  // Adaptive timeout oracle is opt-in (P2). When disabled neither the
  // dispatcher nor the metrics listener consult it.
  if (AppEnvironment.socketTimeoutAdaptiveEnabled) {
    getIt.registerLazySingleton<AgentLatencyOracle>(AgentLatencyOracle.new);
  }

  // PR-L: relay (relay:*) lives on top of the same ConsumerSocketConnection
  // and is opt-in via SOCKET_RELAY_ENABLED. We register both the
  // conversation manager and the dispatcher only when the flag is set so
  // builds keeping the legacy `agents:command` path are not paying for
  // PayloadFrame allocations or extra listeners.
  if (AppEnvironment.socketRelayEnabled) {
    getIt
      ..registerLazySingleton<RelayConversationManager>(
        () => RelayConversationManager(
          connection: getIt<ConsumerSocketConnection>(),
          startTimeout: Duration(
            milliseconds:
                AppEnvironment.socketRelayConversationStartTimeoutMs,
          ),
          endTimeout: Duration(
            milliseconds: AppEnvironment.socketRelayConversationEndTimeoutMs,
          ),
        ),
        dispose: (manager) => manager.dispose(),
      )
      ..registerLazySingleton<RelayCommandDispatcher>(
        () => RelayCommandDispatcherImpl(
          connection: getIt<ConsumerSocketConnection>(),
          conversationManager: getIt<RelayConversationManager>(),
          defaultTimeout: Duration(
            milliseconds: AppEnvironment.socketRelayRequestTimeoutMs,
          ),
          defaultCompression:
              AppEnvironment.socketRelayPayloadFrameCompression,
          defaultStreamInitialWindow:
              AppEnvironment.socketRelayStreamInitialWindow,
          defaultStreamRefillThreshold:
              AppEnvironment.socketRelayStreamRefillThreshold,
        ),
        dispose: (dispatcher) => dispatcher.dispose(),
      );
  }

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

/// PR-K: picks the [ConnectionReadyDecoder] dictated by
/// `SOCKET_CONNECTION_READY_COMPAT_MODE`. Defaults to the migration-window
/// `compat` decoder so production keeps working when the hub still sends
/// raw JSON.
ConnectionReadyDecoder _buildReadyDecoder() {
  switch (AppEnvironment.socketConnectionReadyCompatMode) {
    case ConnectionReadyCompatMode.payloadFrameOnly:
      return PayloadFrameConnectionReadyDecoder();
    case ConnectionReadyCompatMode.rawJsonOnly:
      return const JsonOnlyConnectionReadyDecoder();
    case ConnectionReadyCompatMode.compat:
      return CompatConnectionReadyDecoder(onShape: _logCompatShape);
  }
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
