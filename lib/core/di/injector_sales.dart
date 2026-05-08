import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerInjectorSales(GetIt getIt) {
  getIt
    ..registerSingleton<SalesPreferences>(
      SalesPreferences(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<LoadAvailableAgentsForSales>(
      () => LoadAvailableAgentsForSales(
        getIt<ClientAgentsRepository>(),
        getIt<AgentClientTokenReader>(),
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
    );
}
