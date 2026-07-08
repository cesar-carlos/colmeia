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

        // When relay is available on socket transport, route all SQL
        // (including `useRelay: false`) through relay unary instead of
        // `agents:command`, which hangs when the hub does not respond.
        final base = switch (AppEnvironment.agentBridgeTransport) {
          AgentBridgeTransport.socket => relayFallback ?? legacySocketBase(),
          AgentBridgeTransport.rest => rest,
        };
        // PR-L+ part 1: wrap with the per-call selector when the relay
        // datasource is available (SOCKET_RELAY_ENABLED=true). Requests
        // with `useRelay: true` flow through the relay channel; on REST
        // transport everything else stays on REST.
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
            'baseUsesRelayOnSocket':
                AppEnvironment.agentBridgeTransport ==
                    AgentBridgeTransport.socket &&
                relay != null,
            'baseUsesSocketRestFallback':
                AppEnvironment.agentBridgeTransport ==
                    AgentBridgeTransport.socket &&
                relay == null,
            'relayUsesSocketRestFallback': relay != null,
          },
        );
        return relayWrapped;
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
