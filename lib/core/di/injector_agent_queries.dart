import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_produto_vendido_forma_pagamento_use_case.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_produto_vendido_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_produto_vendido_forma_pagamento_repository.dart';
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
    ..registerLazySingleton<
      ResumoParcelaProdutoVendidoFormaPagamentoRepository
    >(
      () => ResumoParcelaProdutoVendidoFormaPagamentoRepositoryImpl(
        getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerLazySingleton<
      LoadResumoParcelaProdutoVendidoFormaPagamentoUseCase
    >(
      () => LoadResumoParcelaProdutoVendidoFormaPagamentoUseCase(
        getIt<ResumoParcelaProdutoVendidoFormaPagamentoRepository>(),
      ),
    );
}
