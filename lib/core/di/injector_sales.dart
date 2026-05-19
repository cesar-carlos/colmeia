import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_live_map_refresh_metrics.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_live_map_catalog_disk_cache.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/shared/maps/app_location_resolver.dart';
import 'package:colmeia/shared/widgets/charts/app_brazil_store_sales_point_resolver.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerInjectorSales(GetIt getIt) {
  getIt
    ..registerSingleton<SalesPreferences>(
      SalesPreferences(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<SalesSessionService>(
      () => SalesSessionService(getIt<SalesPreferences>()),
    )
    ..registerLazySingleton<LoadAvailableAgentsForSales>(
      () => LoadAvailableAgentsForSales.fromTargetResolver(
        getIt<AgentQueryTargetResolver>(),
      ),
    )
    ..registerLazySingleton<LoadSalesAvailableAgentsUseCase>(
      () =>
          LoadSalesAvailableAgentsUseCase(getIt<LoadAvailableAgentsForSales>()),
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
    ..registerLazySingleton<SalesLiveMapCatalogDiskCache>(
      () => SalesLiveMapCatalogDiskCache(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<SalesLiveMapRefreshMetrics>(
      SalesLiveMapRefreshMetrics.new,
    )
    ..registerFactory<LoadSalesLiveMapUseCase>(
      () => LoadSalesLiveMapUseCase(
        getIt<AgentQueryTargetResolver>(),
        getIt<SalesLiveMapCatalogDiskCache>(),
        getIt<LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase>(),
        getIt<LoadCadastroFilialAcrossAgentsUseCase>(),
        AppBrazilStoreSalesPointResolver(
          locationResolver: getIt<AppLocationResolver>(),
        ),
        refreshMetrics: getIt<SalesLiveMapRefreshMetrics>(),
      ),
    );
}
