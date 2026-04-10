import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_forma_pagamento_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:get_it/get_it.dart';

void registerInjectorOverview(GetIt getIt) {
  getIt
    ..registerLazySingleton<OverviewLocalDataSource>(
      () => OverviewLocalDataSource(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<OverviewRepository>(
      () => OverviewRepositoryImpl(
        localDataSource: getIt<OverviewLocalDataSource>(),
        clientAgentsRepository: getIt(),
        clientTokenStore: getIt<LocalAgentClientTokenStore>(),
        loadResumo:
            getIt<LoadResumoParcelaFormaPagamentoUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadOverviewUseCase>(
      () => LoadOverviewUseCase(getIt<OverviewRepository>()),
    );
}
