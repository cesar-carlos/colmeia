import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/sync/agent_query_facts_prefetch_coordinator.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_online_agent_ids_use_case.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:get_it/get_it.dart';

void registerInjectorOverview(GetIt getIt) {
  // Process-lifetime gate shared with overview + fact prefetch. Route-scoped
  // controllers must not dispose it — see RetryAfterGate class docs.
  if (!getIt.isRegistered<RetryAfterGate>()) {
    getIt.registerLazySingleton<RetryAfterGate>(RetryAfterGate.new);
  }

  getIt
    ..registerLazySingleton<OverviewBatchLoader>(
      () => OverviewBatchLoader(
        targetResolver: getIt<AgentQueryTargetResolver>(),
        planBuilder: getIt<AgentQueryPlanBuilder>(),
        agentQueriesRepository: getIt<AgentQueriesRepository>(),
        loadDailySales: getIt<LoadResumoTotalDiarioVendasUseCase>(),
        loadMonthlyParcels: getIt<LoadResumoParcelasMensalUseCase>(),
        maxParallelReadOnlyBatchItems:
            AppEnvironment.agentSqlOverviewBatchMaxParallelReadOnlyItems,
      ),
    )
    ..registerLazySingleton<OverviewRepository>(
      () => OverviewRepositoryImpl(
        batchLoader: getIt<OverviewBatchLoader>(),
        factsStore: getIt<AgentQueryFactsStore>(),
        factsPrefetchCoordinator: getIt<AgentQueryFactsPrefetchCoordinator>(),
      ),
    )
    ..registerLazySingleton<LoadOverviewUseCase>(
      () => LoadOverviewUseCase(getIt<OverviewRepository>()),
    )
    ..registerLazySingleton<LoadOverviewOnlineAgentIdsUseCase>(
      () => LoadOverviewOnlineAgentIdsUseCase(getIt<ClientAgentsRepository>()),
    );
}
