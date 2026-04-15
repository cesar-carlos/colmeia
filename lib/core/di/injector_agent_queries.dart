import 'package:colmeia/core/config/app_environment.dart';
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
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_forma_pagamento_por_mes_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/municipio_list_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_diario_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_diario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_forma_pagamento_por_mes_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_forma_pagamento_por_mes_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_diario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/municipio_list_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_diario_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_dia_semana_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_forma_pagamento_por_mes_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_mensal_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_vendas_diarias_por_vendedor_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

void registerInjectorAgentQueries(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentQueriesRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeAgentQueriesRemoteDataSource()
          : ApiAgentQueriesRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<AgentQueriesRepository>(
      () => AgentQueriesRepositoryImpl(getIt<AgentQueriesRemoteDataSource>()),
    )
    ..registerLazySingleton<MunicipioListRepository>(
      () => MunicipioListRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<LoadMunicipiosPageUseCase>(
      () => LoadMunicipiosPageUseCase(
        getIt<MunicipioListRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelaFormaPagamentoRepository>(
      () => ResumoParcelaFormaPagamentoRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelaFormaPagamentoUseCase>(
      () => LoadResumoParcelaFormaPagamentoUseCase(
        getIt<ResumoParcelaFormaPagamentoRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelaFormaPagamentoDiarioRepository>(
      () => ResumoParcelaFormaPagamentoDiarioRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelaFormaPagamentoDiarioUseCase>(
      () => LoadResumoParcelaFormaPagamentoDiarioUseCase(
        getIt<ResumoParcelaFormaPagamentoDiarioRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasDiaSemanaRepository>(
      () => ResumoParcelasDiaSemanaRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasDiaSemanaUseCase>(
      () => LoadResumoParcelasDiaSemanaUseCase(
        getIt<ResumoParcelasDiaSemanaRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasAnualRepository>(
      () => ResumoParcelasAnualRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasAnualUseCase>(
      () => LoadResumoParcelasAnualUseCase(
        getIt<ResumoParcelasAnualRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasFormaPagamentoPorMesRepository>(
      () => ResumoParcelasFormaPagamentoPorMesRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasFormaPagamentoPorMesUseCase>(
      () => LoadResumoParcelasFormaPagamentoPorMesUseCase(
        getIt<ResumoParcelasFormaPagamentoPorMesRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoParcelasMensalRepository>(
      () => ResumoParcelasMensalRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<LoadResumoParcelasMensalUseCase>(
      () => LoadResumoParcelasMensalUseCase(
        getIt<ResumoParcelasMensalRepository>(),
      ),
    )
    ..registerLazySingleton<ResumoVendasDiariasPorVendedorRepository>(
      () => ResumoVendasDiariasPorVendedorRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<LoadResumoVendasDiariasPorVendedorUseCase>(
      () => LoadResumoVendasDiariasPorVendedorUseCase(
        getIt<ResumoVendasDiariasPorVendedorRepository>(),
      ),
    )
    ..registerLazySingleton<AgentQueryTargetResolver>(
      () => AgentQueryTargetResolver(
        clientAgentsRepository: getIt(),
        clientTokenReader: getIt<AgentClientTokenReader>(),
      ),
    )
    ..registerLazySingleton<AgentQueryPlanBuilder>(
      AgentQueryPlanBuilder.new,
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
}
