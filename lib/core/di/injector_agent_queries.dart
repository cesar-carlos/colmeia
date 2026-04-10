import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_use_case.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_repository.dart';
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
    );
}
