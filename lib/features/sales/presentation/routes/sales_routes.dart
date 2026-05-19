import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_produto_rank_lucro_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_summary_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_controller.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_daily_totals_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_hub_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_live_map_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_monthly_pnl_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_rank_lucro_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_media_movel_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_under_construction_page.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

List<RouteBase> buildSalesRoutes() {
  final sessionService = getIt<SalesSessionService>();
  final loadSalesAvailableAgentsUseCase =
      getIt<LoadSalesAvailableAgentsUseCase>();
  final resolveSalesAgentClientTokenUseCase =
      getIt<ResolveSalesAgentClientTokenUseCase>();

  return <RouteBase>[
    GoRoute(
      name: AppRoute.sales.name,
      path: AppRoute.sales.path,
      builder: (context, state) => const SalesHubPage(),
    ),
    GoRoute(
      name: AppRoute.salesMonitoring.name,
      path: AppRoute.salesMonitoring.path,
      builder: (context, state) => ChangeNotifierProvider<SalesLiveMapController>(
        create: (_) => SalesLiveMapController(
          sessionService: sessionService,
          loadSalesAvailableAgentsUseCase: loadSalesAvailableAgentsUseCase,
          loadSalesLiveMapUseCase: getIt<LoadSalesLiveMapUseCase>(),
        ),
        child: const SalesLiveMapPage(),
      ),
    ),
    GoRoute(
      name: AppRoute.salesCard.name,
      path: AppRoute.salesCard.path,
      builder: (context, state) {
        final cardId = state.pathParameters['cardId'];
        final l10n = AppLocalizations.of(context);
        if (cardId == null) {
          return AppShellUnderConstructionPage(
            sectionTitle: l10n.shellNavSalesLabel,
          );
        }

        if (cardId == 'produto_rank_lucro') {
          return SalesProdutoRankLucroPage(
            sessionService: sessionService,
            loadSalesAvailableAgentsUseCase: loadSalesAvailableAgentsUseCase,
            resolveSalesAgentClientTokenUseCase:
                resolveSalesAgentClientTokenUseCase,
            loadProdutoVendidoProdutoRankLucroUseCase:
                getIt<LoadProdutoVendidoProdutoRankLucroUseCase>(),
          );
        }

        if (cardId == 'monthly_pnl' || cardId == 'parcelas_mensal_12m') {
          return SalesMonthlyPnlPage(
            sessionService: sessionService,
            loadSalesAvailableAgentsUseCase: loadSalesAvailableAgentsUseCase,
            loadSalesMonthlyPnlLinesUseCase:
                getIt<LoadSalesMonthlyPnlLinesUseCase>(),
            loadSalesDailyTotalsUseCase: getIt<LoadSalesDailyTotalsUseCase>(),
            resolveSalesAgentClientTokenUseCase:
                resolveSalesAgentClientTokenUseCase,
          );
        }

        if (cardId == 'resumo_total_diario_vendas') {
          return SalesDailyTotalsPage(
            sessionService: sessionService,
            loadSalesAvailableAgentsUseCase: loadSalesAvailableAgentsUseCase,
            loadSalesDailyTotalsUseCase: getIt<LoadSalesDailyTotalsUseCase>(),
            resolveSalesAgentClientTokenUseCase:
                resolveSalesAgentClientTokenUseCase,
          );
        }

        if (cardId == 'produto_tendencia_venda') {
          return SalesProdutoTendenciaPage(
            sessionService: sessionService,
            loadSalesAvailableAgentsUseCase: loadSalesAvailableAgentsUseCase,
            resolveSalesAgentClientTokenUseCase:
                resolveSalesAgentClientTokenUseCase,
            loadTrendUseCase:
                getIt<LoadProdutoVendidoTendenciaDeVendaUseCase>(),
            loadTrendSummaryUseCase:
                getIt<LoadProdutoVendidoTendenciaDeVendaSummaryUseCase>(),
            loadGrupoProdutoOptionsUseCase:
                getIt<LoadGrupoProdutoOptionsUseCase>(),
            loadMarcaProdutoOptionsUseCase:
                getIt<LoadMarcaProdutoOptionsUseCase>(),
          );
        }

        if (cardId == 'produto_tendencia_venda_media_movel') {
          return SalesProdutoTendenciaMediaMovelPage(
            sessionService: sessionService,
            loadSalesAvailableAgentsUseCase: loadSalesAvailableAgentsUseCase,
            resolveSalesAgentClientTokenUseCase:
                resolveSalesAgentClientTokenUseCase,
            loadTrendScreenUseCase:
                getIt<
                  LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
                >(),
            loadGrupoProdutoOptionsUseCase:
                getIt<LoadGrupoProdutoOptionsUseCase>(),
          );
        }

        return AppShellUnderConstructionPage(
          sectionTitle: l10n.shellNavSalesLabel,
        );
      },
    ),
  ];
}
