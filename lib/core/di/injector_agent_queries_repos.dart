part of 'injector_agent_queries.dart';

void _registerAgentQueriesRepositoryChain(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentQueriesRepositoryChain>(() {
      final chain = AgentQueriesRepositoryChainFactory.build(
        remoteDataSource: getIt<AgentQueriesRemoteDataSource>(),
        eligibility: getIt<AgentSqlExecutionEligibilityPort>(),
        maxCacheSize: AppEnvironment.agentSqlCacheMaxSize,
        cacheTtl: Duration(milliseconds: AppEnvironment.agentSqlCacheTtlMs),
        catalogCacheTtl: AppEnvironment.agentSqlCatalogCacheTtlMs > 0
            ? Duration(milliseconds: AppEnvironment.agentSqlCatalogCacheTtlMs)
            : null,
        agentSqlRestMaxInflightPerAgent:
            AppEnvironment.agentSqlRestMaxInflightPerAgent,
      );

      final cache = chain.cachingRepository;
      AppLogger.info(
        'AgentQueriesRepository decorator chain initialized',
        context: <String, Object?>{
          'decorators': chain.decorators,
          'agentSqlCacheMaxSize': AppEnvironment.agentSqlCacheMaxSize,
          'agentSqlCacheTtlMs': AppEnvironment.agentSqlCacheTtlMs,
          'agentSqlRestMaxInflightPerAgent':
              AppEnvironment.agentSqlRestMaxInflightPerAgent,
          'sqlCacheHits': cache.cacheHits,
          'sqlCacheMisses': cache.cacheMisses,
          'sqlBatchCacheHits': cache.batchCacheHits,
          'sqlBatchCacheMisses': cache.batchCacheMisses,
          'sqlCacheSize': cache.cacheSize,
        },
      );

      return chain;
    })
    ..registerLazySingleton<MetricsAgentQueriesRepository>(
      () => getIt<AgentQueriesRepositoryChain>().metricsRepository,
    )
    ..registerLazySingleton<AgentQueriesRepository>(
      () => getIt<AgentQueriesRepositoryChain>().repository,
    );
}

void _registerSingleAgentQueryRepositories(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentQueryFactsStore>(
      () => HiveAgentQueryFactsStore(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton(ResumoTotalDiarioVendasCacheStrategy.new)
    ..registerLazySingleton(ResumoParcelasMensalCacheStrategy.new)
    ..registerLazySingleton(ResumoParcelasDiaSemanaCacheStrategy.new)
    ..registerLazySingleton(ResumoProdutoVendaLucratividadeCacheStrategy.new)
    ..registerLazySingleton(
      ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy.new,
    );

  _registerSingle<CadastroFilialRepository, LoadCadastroFilialPageUseCase>(
    getIt,
    repo: () => CadastroFilialRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () =>
        LoadCadastroFilialPageUseCase(getIt<CadastroFilialRepository>()),
  );

  _registerSingle<MunicipioListRepository, LoadMunicipiosPageUseCase>(
    getIt,
    repo: () => MunicipioListRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadMunicipiosPageUseCase(getIt<MunicipioListRepository>()),
  );

  _registerSingle<ClienteOptionsRepository, LoadClienteOptionsUseCase>(
    getIt,
    repo: () => ClienteOptionsRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadClienteOptionsUseCase(getIt<ClienteOptionsRepository>()),
  );

  _registerSingle<FornecedorOptionsRepository, LoadFornecedorOptionsUseCase>(
    getIt,
    repo: () =>
        FornecedorOptionsRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () =>
        LoadFornecedorOptionsUseCase(getIt<FornecedorOptionsRepository>()),
  );

  _registerSingle<
    GrupoProdutoOptionsRepository,
    LoadGrupoProdutoOptionsUseCase
  >(
    getIt,
    repo: () =>
        GrupoProdutoOptionsRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadGrupoProdutoOptionsUseCase(
      getIt<GrupoProdutoOptionsRepository>(),
    ),
  );

  _registerSingle<
    MarcaProdutoOptionsRepository,
    LoadMarcaProdutoOptionsUseCase
  >(
    getIt,
    repo: () =>
        MarcaProdutoOptionsRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadMarcaProdutoOptionsUseCase(
      getIt<MarcaProdutoOptionsRepository>(),
    ),
  );

  _registerSingle<
    GrupoMarcaProdutoOptionsRepository,
    LoadGrupoMarcaProdutoOptionsUseCase
  >(
    getIt,
    repo: () => GrupoMarcaProdutoOptionsRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadGrupoMarcaProdutoOptionsUseCase(
      getIt<GrupoMarcaProdutoOptionsRepository>(),
    ),
  );

  _registerSingle<
    ResumoProdutoVendaRepository,
    LoadResumoProdutoVendaPageUseCase
  >(
    getIt,
    repo: () =>
        ResumoProdutoVendaRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadResumoProdutoVendaPageUseCase(
      getIt<ResumoProdutoVendaRepository>(),
    ),
  );

  _registerSingle<
    ResumoProdutoVendaLucratividadeMensalRepository,
    LoadResumoProdutoVendaLucratividadeMensalUseCase
  >(
    getIt,
    repo: () => ResumoProdutoVendaLucratividadeMensalRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoProdutoVendaLucratividadeMensalUseCase(
      getIt<ResumoProdutoVendaLucratividadeMensalRepository>(),
    ),
  );

  _registerSingle<
    ResumoProdutoVendaLucratividadeRepository,
    LoadResumoProdutoVendaLucratividadeUseCase
  >(
    getIt,
    repo: () {
      final agentQueries = getIt<AgentQueriesRepository>();
      return CachingResumoProdutoVendaLucratividadeRepositoryImpl(
        delegate: ResumoProdutoVendaLucratividadeRepositoryImpl(agentQueries),
        factsStore: getIt<AgentQueryFactsStore>(),
        strategy: getIt<ResumoProdutoVendaLucratividadeCacheStrategy>(),
        agentQueriesRepository: agentQueries,
      );
    },
    useCase: () => LoadResumoProdutoVendaLucratividadeUseCase(
      getIt<ResumoProdutoVendaLucratividadeRepository>(),
    ),
  );

  _registerSingle<
    ProdutoVendidoProdutoRankLucroRepository,
    LoadProdutoVendidoProdutoRankLucroUseCase
  >(
    getIt,
    repo: () => ProdutoVendidoProdutoRankLucroRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadProdutoVendidoProdutoRankLucroUseCase(
      getIt<ProdutoVendidoProdutoRankLucroRepository>(),
    ),
  );

  _registerSingle<
    RankingProdutosFaturamentoRepository,
    LoadRankingProdutosFaturamentoUseCase
  >(
    getIt,
    repo: () => RankingProdutosFaturamentoRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadRankingProdutosFaturamentoUseCase(
      getIt<RankingProdutosFaturamentoRepository>(),
    ),
  );

  _registerSingle<
    ProdutoVendidoTendenciaDeVendaMediaMovelRepository,
    LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase
  >(
    getIt,
    repo: () => ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase(
      getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>(),
    ),
  );
  getIt
    ..registerLazySingleton<
      LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase
    >(
      () => LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase(
        getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
    >(
      () => LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase(
        getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>(),
      ),
    );

  _registerSingle<
    ProdutoVendidoTendenciaDeVendaRepository,
    LoadProdutoVendidoTendenciaDeVendaUseCase
  >(
    getIt,
    repo: () => ProdutoVendidoTendenciaDeVendaRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadProdutoVendidoTendenciaDeVendaUseCase(
      getIt<ProdutoVendidoTendenciaDeVendaRepository>(),
    ),
  );
  getIt.registerLazySingleton<LoadProdutoVendidoTendenciaDeVendaScreenUseCase>(
    () => LoadProdutoVendidoTendenciaDeVendaScreenUseCase(
      getIt<ProdutoVendidoTendenciaDeVendaRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelaFormaPagamentoRepository,
    LoadResumoParcelaFormaPagamentoUseCase
  >(
    getIt,
    repo: () => ResumoParcelaFormaPagamentoRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelaFormaPagamentoUseCase(
      getIt<ResumoParcelaFormaPagamentoRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelaFormaPagamentoRepositoryV2,
    LoadResumoParcelaFormaPagamentoUseCaseV2
  >(
    getIt,
    repo: () => ResumoParcelaFormaPagamentoRepositoryImplV2(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelaFormaPagamentoUseCaseV2(
      getIt<ResumoParcelaFormaPagamentoRepositoryV2>(),
    ),
  );

  _registerSingle<
    ResumoParcelaPorUsuarioRepository,
    LoadResumoParcelaPorUsuarioUseCase
  >(
    getIt,
    repo: () => ResumoParcelaPorUsuarioRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelaPorUsuarioUseCase(
      getIt<ResumoParcelaPorUsuarioRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelaFormaPagamentoDiarioRepository,
    LoadResumoParcelaFormaPagamentoDiarioUseCase
  >(
    getIt,
    repo: () => ResumoParcelaFormaPagamentoDiarioRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelaFormaPagamentoDiarioUseCase(
      getIt<ResumoParcelaFormaPagamentoDiarioRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelasDiaSemanaRepository,
    LoadResumoParcelasDiaSemanaUseCase
  >(
    getIt,
    repo: () {
      final agentQueries = getIt<AgentQueriesRepository>();
      return CachingResumoParcelasDiaSemanaRepositoryImpl(
        delegate: ResumoParcelasDiaSemanaRepositoryImpl(agentQueries),
        factsStore: getIt<AgentQueryFactsStore>(),
        strategy: getIt<ResumoParcelasDiaSemanaCacheStrategy>(),
        agentQueriesRepository: agentQueries,
      );
    },
    useCase: () => LoadResumoParcelasDiaSemanaUseCase(
      getIt<ResumoParcelasDiaSemanaRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelasDiaSemanaUsuarioRepository,
    LoadResumoParcelasDiaSemanaUsuarioUseCase
  >(
    getIt,
    repo: () => ResumoParcelasDiaSemanaUsuarioRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelasDiaSemanaUsuarioUseCase(
      getIt<ResumoParcelasDiaSemanaUsuarioRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelasAnualRepository,
    LoadResumoParcelasAnualUseCase
  >(
    getIt,
    repo: () =>
        ResumoParcelasAnualRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () =>
        LoadResumoParcelasAnualUseCase(getIt<ResumoParcelasAnualRepository>()),
  );

  _registerSingle<
    ResumoParcelasFormaPagamentoPorMesRepository,
    LoadResumoParcelasFormaPagamentoPorMesUseCase
  >(
    getIt,
    repo: () => ResumoParcelasFormaPagamentoPorMesRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoParcelasFormaPagamentoPorMesUseCase(
      getIt<ResumoParcelasFormaPagamentoPorMesRepository>(),
    ),
  );

  _registerSingle<
    ResumoParcelasMensalRepository,
    LoadResumoParcelasMensalUseCase
  >(
    getIt,
    repo: () {
      final agentQueries = getIt<AgentQueriesRepository>();
      return CachingResumoParcelasMensalRepositoryImpl(
        delegate: ResumoParcelasMensalRepositoryImpl(agentQueries),
        factsStore: getIt<AgentQueryFactsStore>(),
        strategy: getIt<ResumoParcelasMensalCacheStrategy>(),
        agentQueriesRepository: agentQueries,
      );
    },
    useCase: () => LoadResumoParcelasMensalUseCase(
      getIt<ResumoParcelasMensalRepository>(),
    ),
  );

  _registerSingle<
    ResumoVendasDiariasPorVendedorRepository,
    LoadResumoVendasDiariasPorVendedorUseCase
  >(
    getIt,
    repo: () => ResumoVendasDiariasPorVendedorRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoVendasDiariasPorVendedorUseCase(
      getIt<ResumoVendasDiariasPorVendedorRepository>(),
    ),
  );

  _registerSingle<
    ResumoTotalDiarioVendasRepository,
    LoadResumoTotalDiarioVendasUseCase
  >(
    getIt,
    repo: () {
      final agentQueries = getIt<AgentQueriesRepository>();
      return CachingResumoTotalDiarioVendasRepositoryImpl(
        delegate: ResumoTotalDiarioVendasRepositoryImpl(agentQueries),
        factsStore: getIt<AgentQueryFactsStore>(),
        strategy: getIt<ResumoTotalDiarioVendasCacheStrategy>(),
        agentQueriesRepository: agentQueries,
      );
    },
    useCase: () => LoadResumoTotalDiarioVendasUseCase(
      getIt<ResumoTotalDiarioVendasRepository>(),
    ),
  );

  _registerSingle<
    ResumoTotalVendasMunicipioFilialDiarioRepository,
    LoadResumoTotalVendasMunicipioFilialDiarioUseCase
  >(
    getIt,
    repo: () => ResumoTotalVendasMunicipioFilialDiarioRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
    useCase: () => LoadResumoTotalVendasMunicipioFilialDiarioUseCase(
      getIt<ResumoTotalVendasMunicipioFilialDiarioRepository>(),
    ),
  );

  _registerSingle<
    ResumoTotalVendasMunicipioFilialPeriodoRepository,
    LoadResumoTotalVendasMunicipioFilialPeriodoUseCase
  >(
    getIt,
    repo: () {
      final agentQueries = getIt<AgentQueriesRepository>();
      return CachingResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl(
        delegate: ResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl(
          agentQueries,
        ),
        factsStore: getIt<AgentQueryFactsStore>(),
        strategy: getIt<ResumoTotalVendasMunicipioFilialPeriodoCacheStrategy>(),
        agentQueriesRepository: agentQueries,
      );
    },
    useCase: () => LoadResumoTotalVendasMunicipioFilialPeriodoUseCase(
      getIt<ResumoTotalVendasMunicipioFilialPeriodoRepository>(),
    ),
  );
}

void _registerSingle<R extends Object, U extends Object>(
  GetIt getIt, {
  required R Function() repo,
  required U Function() useCase,
}) {
  getIt
    ..registerLazySingleton<R>(repo)
    ..registerLazySingleton<U>(useCase);
}
