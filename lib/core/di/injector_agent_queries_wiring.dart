part of 'injector_agent_queries.dart';

/// Attaches SQL metrics export to [SocketMetricsListener] after both stacks
/// are registered.
void wireAgentQueriesSocketMetricsExport(GetIt getIt) {
  if (!getIt.isRegistered<SocketMetricsListener>()) {
    return;
  }
  if (!getIt.isRegistered<MetricsAgentQueriesRepository>()) {
    return;
  }
  getIt<SocketMetricsListener>().sqlAppendix = () {
    final chain = getIt<AgentQueriesRepositoryChain>();
    final metrics = getIt<MetricsAgentQueriesRepository>();
    return <String, Object?>{
      ...metrics.appendixForSocketExport(),
      ...MetricsAgentQueriesRepository.repositoryLayerAppendix(
        cache: chain.cachingRepository,
        coalescing: chain.coalescingRepository,
      ),
      ...AgentQueryFactsStoreMetrics.instance.appendix(),
    };
  };
  AgentQueryFailureSupportMetrics.resolver = () {
    return AgentQueryFailureSupportMetrics.collect(
      channelMetrics: getIt.isRegistered<SocketChannelMetrics>()
          ? getIt<SocketChannelMetrics>()
          : null,
      coalescingRepository: getIt.isRegistered<AgentQueriesRepositoryChain>()
          ? getIt<AgentQueriesRepositoryChain>().coalescingRepository
          : null,
    );
  };
}

/// Wires transport cancel handlers for [AgentQueriesCancelScope].
void wireAgentQueriesCancelScopeHandlers(
  GetIt getIt,
  AgentQueriesCancelScope scope,
) {
  if (getIt.isRegistered<RelayCommandDispatcher>()) {
    final dispatcher = getIt<RelayCommandDispatcher>();
    scope.relayCancelHandler = (clientRequestIds) {
      clientRequestIds.forEach(dispatcher.cancel);
    };
  } else {
    scope.relayCancelHandler = null;
  }

  if (getIt.isRegistered<SocketCommandDispatcher>()) {
    final socket = getIt<SocketCommandDispatcher>();
    scope.socketRpcCancelHandler = (rpcIds) {
      rpcIds.forEach(socket.cancel);
    };
  } else {
    scope.socketRpcCancelHandler = null;
  }

  if (getIt.isRegistered<AgentSqlCancelEmitter>()) {
    final emitter = getIt<AgentSqlCancelEmitter>();
    scope.streamingSqlCancelHandler = (targets) {
      for (final target in targets) {
        unawaited(
          emitter.cancelStream(
            agentId: target.agentId,
            streamId: target.streamId,
            clientToken: target.clientToken,
          ),
        );
      }
    };
  } else {
    scope.streamingSqlCancelHandler = null;
  }
}

/// Wires [AgentQueriesCancelScope.relayCancelHandler] to fail-fast pending
/// relay unary/streaming RPCs when the scope is abandoned.
void wireAgentQueriesRelayCancelHandler(
  GetIt getIt,
  AgentQueriesCancelScope scope,
) {
  wireAgentQueriesCancelScopeHandlers(getIt, scope);
}
