import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcela_produto_vendido_forma_pagamento_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_local_datasource.dart';
import 'package:colmeia/features/dashboards/data/repositories/dashboard_repository_impl.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:get_it/get_it.dart';

void registerInjectorDashboards(GetIt getIt) {
  getIt
    ..registerLazySingleton<DashboardLocalDataSource>(
      () => DashboardLocalDataSource(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(
        localDataSource: getIt<DashboardLocalDataSource>(),
        clientAgentsRepository: getIt(),
        clientTokenStore: getIt<LocalAgentClientTokenStore>(),
        loadResumo:
            getIt<LoadResumoParcelaProdutoVendidoFormaPagamentoUseCase>(),
      ),
    )
    ..registerLazySingleton<LoadDashboardOverviewUseCase>(
      () => LoadDashboardOverviewUseCase(getIt<DashboardRepository>()),
    );
}
