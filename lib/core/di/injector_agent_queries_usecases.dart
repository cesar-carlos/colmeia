part of 'injector_agent_queries.dart';

void _registerAcrossAgentQueryRepositories(GetIt getIt) {
  // mergeAllConcurrency caps parallel bridge calls per wave; aligns with
  // AGENT_QUERY_MERGE_ALL_CONCURRENCY and per-agent inflight limits.
  final mergeAllConcurrency = AppEnvironment.agentQueryMergeAllConcurrency;
  getIt
    ..registerLazySingleton<AgentQueryTargetResolutionCache>(
      InMemoryAgentQueryTargetResolutionCache.new,
    )
    ..registerLazySingleton<AgentQueryTargetResolverImpl>(
      () => AgentQueryTargetResolverImpl(
        clientAgentsRepository: getIt(),
        clientTokenReader: getIt<AgentClientTokenReader>(),
        resolutionCache: getIt<AgentQueryTargetResolutionCache>(),
        policy: getIt<AgentSqlExecutionEligibilityPolicy>(),
      ),
    )
    ..registerLazySingleton<AgentQueryTargetResolver>(
      () => getIt<AgentQueryTargetResolverImpl>(),
    )
    ..registerLazySingleton<AgentQueryTargetWarmUpCoordinator>(
      () => AgentQueryTargetWarmUpCoordinator(
        targetResolver: getIt<AgentQueryTargetResolver>(),
      ),
    )
    ..registerLazySingleton<AgentQueryTargetResolutionInvalidator>(
      () => getIt<AgentQueryTargetResolverImpl>(),
    )
    ..registerLazySingleton<AgentQueryPlanBuilder>(
      () => AgentQueryPlanBuilder(
        sqlPresencePolicy: getIt<AgentSqlExecutionEligibilityPolicy>(),
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelaFormaPagamentoRow>>(
      () => AgentQueryExecutor<ResumoParcelaFormaPagamentoRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoParcelaFormaPagamentoRowV2>
    >(
      () => AgentQueryExecutor<ResumoParcelaFormaPagamentoRowV2>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelaPorUsuarioRow>>(
      () => AgentQueryExecutor<ResumoParcelaPorUsuarioRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoVendaProdutoDiarioRow>>(
      () => AgentQueryExecutor<ResumoVendaProdutoDiarioRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasDiaSemanaRow>>(
      () => AgentQueryExecutor<ResumoParcelasDiaSemanaRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoParcelasDiaSemanaUsuarioRow>
    >(
      () => AgentQueryExecutor<ResumoParcelasDiaSemanaUsuarioRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasAnualRow>>(
      () => AgentQueryExecutor<ResumoParcelasAnualRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow>
    >(
      () => AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasMensalRow>>(
      () => AgentQueryExecutor<ResumoParcelasMensalRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>
    >(
      () => AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoTotalDiarioVendasRow>>(
      () => AgentQueryExecutor<ResumoTotalDiarioVendasRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<CadastroFilialRow>>(
      () => AgentQueryExecutor<CadastroFilialRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoTotalVendasMunicipioFilialDiarioRow>
    >(
      () => AgentQueryExecutor<ResumoTotalVendasMunicipioFilialDiarioRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>
    >(
      () => AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<ResumoParcelaFormaPagamentoAcrossAgentsRepository>(
      () => ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelaFormaPagamentoRow>>(),
        loadResumo: getIt<LoadResumoParcelaFormaPagamentoUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase>(
      () => LoadResumoParcelaFormaPagamentoAcrossAgentsUseCase(
        getIt<ResumoParcelaFormaPagamentoAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoParcelaFormaPagamentoAcrossAgentsRepositoryV2
    >(
      () => ResumoParcelaFormaPagamentoAcrossAgentsRepositoryImplV2(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelaFormaPagamentoRowV2>>(),
        loadResumo: getIt<LoadResumoParcelaFormaPagamentoUseCaseV2>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoParcelaFormaPagamentoAcrossAgentsUseCaseV2
    >(
      () => LoadResumoParcelaFormaPagamentoAcrossAgentsUseCaseV2(
        getIt<ResumoParcelaFormaPagamentoAcrossAgentsRepositoryV2>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelaPorUsuarioAcrossAgentsRepository>(
      () => ResumoParcelaPorUsuarioAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelaPorUsuarioRow>>(),
        loadResumo: getIt<LoadResumoParcelaPorUsuarioUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelaPorUsuarioAcrossAgentsUseCase>(
      () => LoadResumoParcelaPorUsuarioAcrossAgentsUseCase(
        getIt<ResumoParcelaPorUsuarioAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoParcelaFormaPagamentoDiarioAcrossAgentsRepository
    >(
      () => ResumoParcelaFormaPagamentoDiarioAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoVendaProdutoDiarioRow>>(),
        loadResumo: getIt<LoadResumoParcelaFormaPagamentoDiarioUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoParcelaFormaPagamentoDiarioAcrossAgentsUseCase
    >(
      () => LoadResumoParcelaFormaPagamentoDiarioAcrossAgentsUseCase(
        getIt<ResumoParcelaFormaPagamentoDiarioAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasDiaSemanaAcrossAgentsRepository>(
      () => ResumoParcelasDiaSemanaAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelasDiaSemanaRow>>(),
        loadResumo: getIt<LoadResumoParcelasDiaSemanaUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasDiaSemanaAcrossAgentsUseCase>(
      () => LoadResumoParcelasDiaSemanaAcrossAgentsUseCase(
        getIt<ResumoParcelasDiaSemanaAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoParcelasDiaSemanaUsuarioAcrossAgentsRepository
    >(
      () => ResumoParcelasDiaSemanaUsuarioAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<AgentQueryExecutor<ResumoParcelasDiaSemanaUsuarioRow>>(),
        loadResumo: getIt<LoadResumoParcelasDiaSemanaUsuarioUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase
    >(
      () => LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase(
        getIt<ResumoParcelasDiaSemanaUsuarioAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasAnualAcrossAgentsRepository>(
      () => ResumoParcelasAnualAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelasAnualRow>>(),
        loadResumo: getIt<LoadResumoParcelasAnualUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasAnualAcrossAgentsUseCase>(
      () => LoadResumoParcelasAnualAcrossAgentsUseCase(
        getIt<ResumoParcelasAnualAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepository
    >(
      () => ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow>>(),
        loadResumo: getIt<LoadResumoParcelasFormaPagamentoPorMesUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase
    >(
      () => LoadResumoParcelasFormaPagamentoPorMesAcrossAgentsUseCase(
        getIt<ResumoParcelasFormaPagamentoPorMesAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasMensalAcrossAgentsRepository>(
      () => ResumoParcelasMensalAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoParcelasMensalRow>>(),
        loadResumo: getIt<LoadResumoParcelasMensalUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasMensalAcrossAgentsUseCase>(
      () => LoadResumoParcelasMensalAcrossAgentsUseCase(
        getIt<ResumoParcelasMensalAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoVendasDiariasPorVendedorAcrossAgentsRepository
    >(
      () => ResumoVendasDiariasPorVendedorAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>>(),
        loadResumo: getIt<LoadResumoVendasDiariasPorVendedorUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorAcrossAgentsUseCase(
        getIt<ResumoVendasDiariasPorVendedorAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoTotalDiarioVendasAcrossAgentsRepository>(
      () => ResumoTotalDiarioVendasAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<ResumoTotalDiarioVendasRow>>(),
        loadResumo: getIt<LoadResumoTotalDiarioVendasUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadResumoTotalDiarioVendasAcrossAgentsUseCase>(
      () => LoadResumoTotalDiarioVendasAcrossAgentsUseCase(
        getIt<ResumoTotalDiarioVendasAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepository
    >(
      () => ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<
              AgentQueryExecutor<ResumoTotalVendasMunicipioFilialDiarioRow>
            >(),
        loadResumo: getIt<LoadResumoTotalVendasMunicipioFilialDiarioUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase
    >(
      () => LoadResumoTotalVendasMunicipioFilialDiarioAcrossAgentsUseCase(
        getIt<ResumoTotalVendasMunicipioFilialDiarioAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<
      ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepository
    >(
      () => ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor:
            getIt<
              AgentQueryExecutor<ResumoTotalVendasMunicipioFilialPeriodoRow>
            >(),
        loadResumo: getIt<LoadResumoTotalVendasMunicipioFilialPeriodoUseCase>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase
    >(
      () => LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase(
        getIt<ResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<CadastroFilialAcrossAgentsRepository>(
      () => CadastroFilialAcrossAgentsRepositoryImpl(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        executor: getIt<AgentQueryExecutor<CadastroFilialRow>>(),
        loadCadastroFilial: getIt<LoadCadastroFilialPageUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadCadastroFilialAcrossAgentsUseCase>(
      () => LoadCadastroFilialAcrossAgentsUseCase(
        getIt<CadastroFilialAcrossAgentsRepository>(),
      ),
    );
}

void _registerFilterOptionsRepositories(GetIt getIt) {
  final mergeAllConcurrency = AppEnvironment.agentQueryMergeAllConcurrency;
  getIt
    ..registerLazySingleton<
      ResumoVendasDiariasPorVendedorFilterOptionsRepository
    >(
      () => ResumoVendasDiariasPorVendedorFilterOptionsRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase(
        getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase(
        getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase(
        getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>(),
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>
    >(
      () => AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
    >(
      () => AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>(
        mergeAllConcurrency: mergeAllConcurrency,
      ),
    )
    ..registerLazySingleton<
      AgentQueryExecutor<
        ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
      >
    >(
      () =>
          AgentQueryExecutor<
            ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
          >(
            mergeAllConcurrency: mergeAllConcurrency,
          ),
    )
    ..registerLazySingleton<
      ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
    >(
      () =>
          ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl(
            targetResolver: getIt<AgentQueryTargetResolver>(),
            planBuilder: getIt<AgentQueryPlanBuilder>(),
            vendedorExecutor:
                getIt<
                  AgentQueryExecutor<
                    ResumoVendasDiariasPorVendedorVendedorOption
                  >
                >(),
            textExecutor:
                getIt<
                  AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
                >(),
            allOptionsBatchExecutor:
                getIt<
                  AgentQueryExecutor<
                    ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch
                  >
                >(),
            filterOptionsRepository:
                getIt<ResumoVendasDiariasPorVendedorFilterOptionsRepository>(),
            loadVendedorOptions:
                getIt<
                  LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase
                >(),
            loadBairroOptions:
                getIt<LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase>(),
            loadMunicipioOptions:
                getIt<
                  LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase
                >(),
          ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase
    >(
      () =>
          LoadResumoVendasDiariasPorVendedorVendedorOptionsAcrossAgentsUseCase(
            getIt<
              ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
            >(),
          ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase
    >(
      () => LoadResumoVendasDiariasPorVendedorBairroOptionsAcrossAgentsUseCase(
        getIt<
          ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
        >(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase
    >(
      () =>
          LoadResumoVendasDiariasPorVendedorMunicipioOptionsAcrossAgentsUseCase(
            getIt<
              ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
            >(),
          ),
    )
    ..registerLazySingleton<
      LoadResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgentsUseCase
    >(
      () =>
          LoadResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgentsUseCase(
            getIt<
              ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepository
            >(),
          ),
    );
}

void _registerStreamingRelay(GetIt getIt) {
  // PR-L+ p3: streaming companion datasource. Lives next to the
  // unary registrations because both share the same body mapper and
  // are gated by the same env (`SOCKET_RELAY_ENABLED`). Registered
  // unconditionally as a lazy singleton; the factory checks
  // `RelayCommandDispatcher` at construction time, so builds without
  // the relay layer simply never resolve it.
  if (getIt.isRegistered<RelayCommandDispatcher>()) {
    getIt.registerLazySingleton<AgentQueriesStreamingRemoteDataSource>(
      () => RelayStreamingAgentQueriesRemoteDataSource(
        dispatcher: getIt<RelayCommandDispatcher>(),
        bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
        compression: AppEnvironment.socketRelayPayloadFrameCompression,
      ),
    );
  }
}
