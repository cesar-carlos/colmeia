import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/relay/relay_command_dispatcher.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_municipios_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_diario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_diario_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_anual_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_anual_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_produto_rank_lucro_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execution_eligibility_checker.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_streaming_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/collecting_relay_streaming_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/hybrid_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/relay_streaming_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/socket_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/datasources/socket_with_rest_fallback_agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/adaptive_timeout_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/circuit_breaker_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/coalescing_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/gated_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/metrics_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/municipio_list_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_diario_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_diario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_usuario_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_usuario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_forma_pagamento_por_mes_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_forma_pagamento_por_mes_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_produto_rank_lucro_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_lucratividade_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_lucratividade_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/retrying_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_sql_execution_eligibility_port.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/municipio_list_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_usuario_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_usuario_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_produto_rank_lucro_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_mensal_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_lucratividade_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_produto_venda_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

void registerInjectorAgentQueries(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentSqlExecutionEligibilityPolicy>(
      () => const AgentSqlExecutionEligibilityPolicy(),
    )
    ..registerLazySingleton<AgentSqlExecuteRequestToBridgeBody>(
      () => const AgentSqlExecuteRequestToBridgeBody(),
    )
    ..registerLazySingleton<AgentQueriesRemoteDataSource>(
      () {
        if (AppEnvironment.useFakeBackend) {
          return FakeAgentQueriesRemoteDataSource();
        }
        final base = switch (AppEnvironment.agentBridgeTransport) {
          AgentBridgeTransport.socket => () {
            final rest = ApiAgentQueriesRemoteDataSource(
              dio: getIt<Dio>(),
              bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
            );
            return SocketWithRestFallbackAgentQueriesRemoteDataSource(
              socketDelegate: SocketAgentQueriesRemoteDataSource(
                sender: getIt<AgentCommandSender>(),
                bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
              ),
              restDelegate: rest,
              onFallback: (trigger) => AppLogger.warning(
                'AgentQueriesRemoteDataSource latched to REST fallback',
                context: <String, Object?>{
                  'triggerCode': trigger.code,
                  'triggerMessage': trigger.message,
                },
              ),
            );
          }(),
          AgentBridgeTransport.rest => ApiAgentQueriesRemoteDataSource(
            dio: getIt<Dio>(),
            bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
          ),
        };
        // PR-L+ part 1: wrap with the per-call selector when the relay
        // datasource is available (SOCKET_RELAY_ENABLED=true). Requests
        // with `useRelay: true` flow through the relay channel; everything
        // else stays on the legacy channel byte-for-byte identical.
        final relay = _resolveRelayDatasource(getIt);
        final relayWrapped = relay == null
            ? base
            : HybridAgentQueriesRemoteDataSource(
                baseDelegate: base,
                relayDelegate: relay,
              );
        AppLogger.info(
          'AgentQueriesRemoteDataSource initialized',
          context: <String, Object?>{
            'transport': AppEnvironment.agentBridgeTransport.name,
            'relayEnabled': relay != null,
            'fallbackEnabled':
                AppEnvironment.agentBridgeTransport ==
                    AgentBridgeTransport.socket,
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
    )
    ..registerLazySingleton<AgentQueriesRepository>(
      () {
        // Decorator chain (outermost to innermost):
        // 1. Gated: validates requestingUserId
        // 2. CircuitBreaker: fail-fast during hub overload
        // 3. Caching: returns from cache when possible
        // 4. Coalescing: deduplicates identical in-flight requests
        // 5. Metrics: records latency and success/failure stats
        // 6. AdaptiveTimeout: adjusts timeouts based on history
        // 7. Retrying: exponential backoff on transient failures
        // 8. AgentQueriesRepositoryImpl: actual hub/bridge call

        final base = AgentQueriesRepositoryImpl(
          getIt<AgentQueriesRemoteDataSource>(),
        );

        final retrying = RetryingAgentQueriesRepository(
          delegate: base,
        );

        final adaptiveTimeout = AdaptiveTimeoutAgentQueriesRepository(
          delegate: retrying,
        );

        final metrics = MetricsAgentQueriesRepository(
          delegate: adaptiveTimeout,
        );

        final coalescing = CoalescingAgentQueriesRepository(
          delegate: metrics,
        );

        final caching = CachingAgentQueriesRepository(
          delegate: coalescing,
        );

        final circuitBreaker = CircuitBreakerAgentQueriesRepository(
          delegate: caching,
        );

        final gated = GatedAgentQueriesRepository(
          delegate: circuitBreaker,
          eligibility: getIt<AgentSqlExecutionEligibilityPort>(),
        );

        AppLogger.info(
          'AgentQueriesRepository decorator chain initialized',
          context: <String, Object?>{
            'decorators': [
              'GatedAgentQueriesRepository',
              'CircuitBreakerAgentQueriesRepository',
              'CachingAgentQueriesRepository',
              'CoalescingAgentQueriesRepository',
              'MetricsAgentQueriesRepository',
              'AdaptiveTimeoutAgentQueriesRepository',
              'RetryingAgentQueriesRepository',
              'AgentQueriesRepositoryImpl',
            ],
          },
        );

        return gated;
      },
    );

  _registerSingle<MunicipioListRepository, LoadMunicipiosPageUseCase>(
    getIt,
    repo: () => MunicipioListRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadMunicipiosPageUseCase(getIt<MunicipioListRepository>()),
  );

  _registerSingle<ResumoProdutoVendaRepository, LoadResumoProdutoVendaPageUseCase>(
    getIt,
    repo: () => ResumoProdutoVendaRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadResumoProdutoVendaPageUseCase(getIt<ResumoProdutoVendaRepository>()),
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
    repo: () => ResumoProdutoVendaLucratividadeRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
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
    repo: () => ResumoParcelasDiaSemanaRepositoryImpl(
      getIt<AgentQueriesRepository>(),
    ),
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

  _registerSingle<ResumoParcelasAnualRepository, LoadResumoParcelasAnualUseCase>(
    getIt,
    repo: () => ResumoParcelasAnualRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadResumoParcelasAnualUseCase(getIt<ResumoParcelasAnualRepository>()    ),
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

  _registerSingle<ResumoParcelasMensalRepository, LoadResumoParcelasMensalUseCase>(
    getIt,
    repo: () => ResumoParcelasMensalRepositoryImpl(getIt<AgentQueriesRepository>()),
    useCase: () => LoadResumoParcelasMensalUseCase(getIt<ResumoParcelasMensalRepository>()),
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

  getIt
    ..registerLazySingleton<AgentQueryTargetResolver>(
      () => AgentQueryTargetResolver(
        clientAgentsRepository: getIt(),
        clientTokenReader: getIt<AgentClientTokenReader>(),
        policy: getIt<AgentSqlExecutionEligibilityPolicy>(),
      ),
    )
    ..registerLazySingleton<AgentQueryPlanBuilder>(
      () => AgentQueryPlanBuilder(
        sqlPresencePolicy: getIt<AgentSqlExecutionEligibilityPolicy>(),
      ),
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelaFormaPagamentoRow>>(
      AgentQueryExecutor<ResumoParcelaFormaPagamentoRow>.new,
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoVendaProdutoDiarioRow>>(
      AgentQueryExecutor<ResumoVendaProdutoDiarioRow>.new,
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasDiaSemanaRow>>(
      AgentQueryExecutor<ResumoParcelasDiaSemanaRow>.new,
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoParcelasDiaSemanaUsuarioRow>
    >(
      AgentQueryExecutor<ResumoParcelasDiaSemanaUsuarioRow>.new,
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasAnualRow>>(
      AgentQueryExecutor<ResumoParcelasAnualRow>.new,
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow>
    >(
      AgentQueryExecutor<ResumoParcelasFormaPagamentoPorMesRow>.new,
    )
    ..registerLazySingleton<AgentQueryExecutor<ResumoParcelasMensalRow>>(
      AgentQueryExecutor<ResumoParcelasMensalRow>.new,
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>
    >(
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorRow>.new,
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
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>.new,
    )
    ..registerLazySingleton<
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
    >(
      AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>.new,
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
    );

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

/// Helper to reduce boilerplate when registering a simple repository + use case pair.
void _registerSingle<R extends Object, U extends Object>(
  GetIt getIt, {
  required R Function() repo,
  required U Function() useCase,
}) {
  getIt
    ..registerLazySingleton<R>(repo)
    ..registerLazySingleton<U>(useCase);
}

/// Returns the relay-backed datasource when the relay layer is available.
/// Prefer the collected streaming adapter when the streaming port is
/// registered so repositories opting into `useRelay` get the lower-memory
/// relay wire path without changing their unary `Future<Map>` contract.
AgentQueriesRemoteDataSource? _resolveRelayDatasource(GetIt getIt) {
  if (!getIt.isRegistered<RelayCommandDispatcher>()) {
    return null;
  }
  if (getIt.isRegistered<AgentQueriesStreamingRemoteDataSource>()) {
    return CollectingRelayStreamingAgentQueriesRemoteDataSource(
      streamingDelegate: getIt<AgentQueriesStreamingRemoteDataSource>(),
    );
  }
  return RelayAgentQueriesRemoteDataSource(
    dispatcher: getIt<RelayCommandDispatcher>(),
    bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
    compression: AppEnvironment.socketRelayPayloadFrameCompression,
  );
}
