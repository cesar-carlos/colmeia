import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/produto_vendido_tendencia_de_venda_media_movel_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/application/load_media_movel_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_branch_location_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_in_memory_catalog_cache.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_batch_loader.dart';
import 'package:colmeia/features/sales/application/ports/sales_live_map_catalog_cache.dart';
import 'package:colmeia/features/sales/application/ports/sales_preferences_port.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_loader_impl.dart';
import 'package:colmeia/features/sales/data/sales_live_map_catalog_disk_cache.dart';
import 'package:colmeia/features/sales/data/sales_live_map_point_resolver_adapter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/contracts/sales_live_map_point_resolver.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_cache.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerInjectorSales(GetIt getIt) {
  if (!getIt.isRegistered<RetryAfterGate>()) {
    getIt.registerLazySingleton<RetryAfterGate>(RetryAfterGate.new);
  }

  getIt
    ..registerSingleton<SalesPreferences>(
      SalesPreferences(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<SalesPreferencesPort>(
      () => getIt<SalesPreferences>(),
    )
    ..registerLazySingleton<SalesSessionService>(
      () => SalesSessionService(getIt<SalesPreferencesPort>()),
    )
    ..registerLazySingleton<LoadAvailableAgentsForSales>(
      () => LoadAvailableAgentsForSales.fromTargetResolver(
        getIt<AgentQueryTargetResolver>(),
        resolutionCache: getIt<AgentQueryTargetResolutionCache>(),
      ),
    )
    ..registerLazySingleton<ResolveSalesAgentClientTokenUseCase>(
      () =>
          ResolveSalesAgentClientTokenUseCase(getIt<AgentClientTokenReader>()),
    )
    ..registerFactory<LoadSalesMonthlyPnlLinesUseCase>(
      () => LoadSalesMonthlyPnlLinesUseCase(
        getIt<LoadResumoProdutoVendaLucratividadeMensalUseCase>(),
      ),
    )
    ..registerFactory<LoadSalesDailyTotalsUseCase>(
      () => LoadSalesDailyTotalsUseCase(
        getIt<LoadResumoTotalDiarioVendasUseCase>(),
      ),
    )
    ..registerFactory<LoadMediaMovelRowsForShareUseCase>(
      () => LoadMediaMovelRowsForShareUseCase(
        getIt<ProdutoVendidoTendenciaDeVendaMediaMovelRepository>(),
      ),
    )
    ..registerLazySingleton<SalesLiveMapCatalogDiskCache>(
      () => SalesLiveMapCatalogDiskCache(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<SalesLiveMapCatalogCache>(
      () => getIt<SalesLiveMapCatalogDiskCache>(),
    )
    ..registerLazySingleton<SalesLiveMapRefreshMetrics>(
      SalesLiveMapRefreshMetrics.new,
    )
    ..registerLazySingleton<SalesLiveMapInMemoryCatalogCache>(
      () => SalesLiveMapInMemoryCatalogCache(
        maxEntries: SalesLiveMapPolicies.branchCatalogCacheMaxEntries,
        ttl: SalesLiveMapPolicies.branchCatalogCacheTtl,
      ),
    )
    ..registerLazySingleton<SalesLiveMapBranchLocationCache>(
      () => SalesLiveMapBranchLocationCache(
        maxEntries: SalesLiveMapPolicies.branchLocationCacheMaxEntries,
        ttl: SalesLiveMapPolicies.branchLocationCacheTtl,
      ),
    )
    ..registerLazySingleton<SalesLiveMapPointResolver>(
      () => SalesLiveMapPointResolverAdapter(
        delegate: AppBrazilStoreSalesPointResolver(
          locationResolver: getIt<AppLocationResolver>(),
        ),
      ),
    )
    ..registerLazySingleton<SalesLiveMapBatchLoader>(
      () => SalesLiveMapBatchLoaderImpl(
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: getIt<AgentQueriesRepository>(),
      ),
    )
    ..registerFactory<LoadSalesLiveMapUseCase>(
      () => LoadSalesLiveMapUseCase(
        getIt<AgentQueryTargetResolver>(),
        getIt<SalesLiveMapCatalogCache>(),
        getIt<LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase>(),
        getIt<LoadCadastroFilialAcrossAgentsUseCase>(),
        getIt<SalesLiveMapPointResolver>(),
        refreshMetrics: getIt<SalesLiveMapRefreshMetrics>(),
        branchCatalogCache: getIt<SalesLiveMapInMemoryCatalogCache>(),
        branchLocationCache: getIt<SalesLiveMapBranchLocationCache>(),
        batchLoader: getIt<SalesLiveMapBatchLoader>(),
      ),
    );
}
