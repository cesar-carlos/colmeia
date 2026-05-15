import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
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
    ..registerLazySingleton<LoadAvailableAgentsForSales>(
      () => LoadAvailableAgentsForSales.fromTargetResolver(
        getIt<AgentQueryTargetResolver>(),
      ),
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
    ..registerFactory<LoadSalesLiveMapUseCase>(
      () => LoadSalesLiveMapUseCase(
        getIt<LoadResumoTotalVendasMunicipioFilialPeriodoAcrossAgentsUseCase>(),
        getIt<LoadCadastroFilialAcrossAgentsUseCase>(),
        AppBrazilStoreSalesPointResolver(
          locationResolver: getIt<AppLocationResolver>(),
        ),
      ),
    );
}
