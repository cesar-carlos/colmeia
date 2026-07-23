part of 'injector_agent_queries.dart';

void _onAgentQueriesRestFallbackLatched(
  GetIt getIt,
  SocketDispatchException trigger,
  String latchLabel,
) {
  if (getIt.isRegistered<SocketChannelMetrics>()) {
    getIt<SocketChannelMetrics>().recordRestFallbackLatch();
  }
  AppLogger.warning(
    '$latchLabel latched to REST fallback',
    context: <String, Object?>{
      'triggerCode': trigger.code,
      'triggerMessage': trigger.message,
      'transport': AppEnvironment.agentBridgeTransport.wireValue,
    },
  );
  unawaited(
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'agent_queries.transport',
        message: 'REST fallback latched ($latchLabel)',
        data: <String, String>{
          'triggerCode': trigger.code,
          'triggerMessage': trigger.message,
          'latchLabel': latchLabel,
        },
        level: SentryLevel.warning,
      ),
    ),
  );
}

void _onAgentQueriesRestFallbackTemporaryLatched(
  GetIt getIt,
  String latchLabel, {
  required String reason,
  required Object trigger,
}) {
  if (getIt.isRegistered<SocketChannelMetrics>()) {
    getIt<SocketChannelMetrics>().recordRestFallbackTemporaryLatch();
  }
  AppLogger.warning(
    '$latchLabel temporarily latched to REST fallback',
    context: <String, Object?>{
      'reason': reason,
      'trigger': trigger.toString(),
      'transport': AppEnvironment.agentBridgeTransport.wireValue,
    },
  );
  unawaited(
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'agent_queries.transport',
        message: 'REST temporary fallback latched ($latchLabel)',
        data: <String, String>{
          'reason': reason,
          'trigger': trigger.toString(),
          'latchLabel': latchLabel,
        },
        level: SentryLevel.warning,
      ),
    ),
  );
}

void _registerAgentQueryTransport(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentSqlExecutionEligibilityPolicy>(
      () => const AgentSqlExecutionEligibilityPolicy(),
    )
    ..registerLazySingleton<AgentSqlExecuteRequestToBridgeBody>(
      () => const AgentSqlExecuteRequestToBridgeBody(),
    )
    ..registerLazySingleton<AgentSqlExecuteBatchRequestToBridgeBody>(
      () => const AgentSqlExecuteBatchRequestToBridgeBody(),
    )
    ..registerLazySingleton<AgentQueriesRemoteDataSource>(
      () {
        if (AppEnvironment.useFakeBackend) {
          return FakeAgentQueriesRemoteDataSource();
        }
        final rest = ApiAgentQueriesRemoteDataSource(
          dio: getIt<Dio>(),
          bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
          onServerTimings: getIt.isRegistered<SocketChannelMetrics>()
              ? (timings) =>
                    getIt<SocketChannelMetrics>().recordServerTimings(timings)
              : null,
        );
        final relay = _resolveRelayDatasource(getIt);
        AgentQueriesRemoteDataSource wrapWithRestFallback({
          required AgentQueriesRemoteDataSource socketDelegate,
          required String latchLabel,
        }) {
          return SocketWithRestFallbackAgentQueriesRemoteDataSource(
            socketDelegate: socketDelegate,
            restDelegate: rest,
            sessionEvents: getIt.isRegistered<AuthSessionEvents>()
                ? getIt<AuthSessionEvents>()
                : null,
            onFallback: (trigger) =>
                _onAgentQueriesRestFallbackLatched(getIt, trigger, latchLabel),
            onTemporaryFallback: ({required reason, required trigger}) =>
                _onAgentQueriesRestFallbackTemporaryLatched(
                  getIt,
                  latchLabel,
                  reason: reason,
                  trigger: trigger,
                ),
          );
        }

        final relayFallback = relay == null
            ? null
            : wrapWithRestFallback(
                socketDelegate: relay,
                latchLabel: 'Relay AgentQueriesRemoteDataSource',
              );
        AgentQueriesRemoteDataSource legacySocketBase() {
          return wrapWithRestFallback(
            socketDelegate: SocketAgentQueriesRemoteDataSource(
              sender: getIt<AgentCommandSender>(),
              bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
            ),
            latchLabel: 'AgentQueriesRemoteDataSource',
          );
        }

        // Socket base channel is always `agents:command`. Relay is selected
        // per-call via Hybrid when `useRelay: true` (and relay is registered).
        // Do not collapse base→relay: that made A/B impossible and hid hangs
        // that are specific to the hub→agent relay hop.
        // Escape hatch: `E2E_DISABLE_RELAY_DISPATCH=true` skips relay DI so
        // even `useRelay: true` falls through Hybrid bypass / single base.
        final base = switch (AppEnvironment.agentBridgeTransport) {
          AgentBridgeTransport.socket => legacySocketBase(),
          AgentBridgeTransport.rest => rest,
        };
        final relayWrapped = relay == null
            ? base
            : HybridAgentQueriesRemoteDataSource(
                baseDelegate: base,
                relayDelegate: relayFallback,
              );
        AppLogger.info(
          'AgentQueriesRemoteDataSource initialized',
          context: <String, Object?>{
            'transport': AppEnvironment.agentBridgeTransport.wireValue,
            'relayEnabled': relay != null,
            'baseChannel': switch (AppEnvironment.agentBridgeTransport) {
              AgentBridgeTransport.socket => 'agents:command',
              AgentBridgeTransport.rest => 'rest',
            },
            'e2eDisableRelayDispatch': AppEnvironment.e2eDisableRelayDispatch,
            'baseUsesSocketRestFallback':
                AppEnvironment.agentBridgeTransport ==
                AgentBridgeTransport.socket,
            'relayUsesSocketRestFallback': relay != null,
          },
        );
        return relayWrapped;
      },
      dispose: (datasource) {
        if (datasource is SocketWithRestFallbackAgentQueriesRemoteDataSource) {
          unawaited(datasource.dispose());
        } else if (datasource is HybridAgentQueriesRemoteDataSource) {
          unawaited(datasource.dispose());
        }
      },
    )
    ..registerLazySingleton<AgentSqlExecutionEligibilityPort>(
      () => AgentSqlExecutionEligibilityChecker(
        clientAgentsRepository: getIt<ClientAgentsRepository>(),
        policy: getIt<AgentSqlExecutionEligibilityPolicy>(),
      ),
    );
}

AgentQueriesRemoteDataSource? _resolveRelayDatasource(GetIt getIt) {
  if (!getIt.isRegistered<RelayCommandDispatcher>()) {
    return null;
  }

  final rawStreamingDelegate =
      getIt.isRegistered<AgentQueriesStreamingRemoteDataSource>()
      ? getIt<AgentQueriesStreamingRemoteDataSource>()
      : RelayStreamingAgentQueriesRemoteDataSource(
          dispatcher: getIt<RelayCommandDispatcher>(),
          bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
          compression: AppEnvironment.socketRelayPayloadFrameCompression,
        );

  final maxBufferedRows =
      AppEnvironment.socketStreamSqlCollectorMaxBufferedRows;
  final collector = maxBufferedRows > 0
      ? BridgeShapedSqlExecuteCollector(maxBufferedRows: maxBufferedRows)
      : const BridgeShapedSqlExecuteCollector();

  final unaryDelegate = RelayAgentQueriesRemoteDataSource(
    dispatcher: getIt<RelayCommandDispatcher>(),
    bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
    batchBodyMapper: getIt<AgentSqlExecuteBatchRequestToBridgeBody>(),
    compression: AppEnvironment.socketRelayPayloadFrameCompression,
  );

  final streamingRelayDelegate =
      CollectingRelayStreamingAgentQueriesRemoteDataSource(
        streamingDelegate: rawStreamingDelegate,
        batchDelegate: unaryDelegate,
        collector: collector,
        maxConcurrentPerAgent:
            AppEnvironment.agentSqlRelayStreamingMaxConcurrentPerAgent,
      );

  return RoutingRelayAgentQueriesRemoteDataSource(
    unaryDelegate: unaryDelegate,
    streamingDelegate: streamingRelayDelegate,
  );
}
