import 'package:colmeia/app/router/app_routes.dart';
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

List<RouteBase> buildSalesRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.sales.name,
      path: AppRoute.sales.path,
      builder: (context, state) => const SalesHubPage(),
    ),
    GoRoute(
      name: AppRoute.salesMonitoring.name,
      path: AppRoute.salesMonitoring.path,
      builder: (context, state) => const SalesLiveMapPage(),
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
          return const SalesProdutoRankLucroPage();
        }

        if (cardId == 'monthly_pnl' || cardId == 'parcelas_mensal_12m') {
          return const SalesMonthlyPnlPage();
        }

        if (cardId == 'resumo_total_diario_vendas') {
          return const SalesDailyTotalsPage();
        }

        if (cardId == 'produto_tendencia_venda') {
          return const SalesProdutoTendenciaPage();
        }

        if (cardId == 'produto_tendencia_venda_media_movel') {
          return const SalesProdutoTendenciaMediaMovelPage();
        }

        return AppShellUnderConstructionPage(
          sectionTitle: l10n.shellNavSalesLabel,
        );
      },
    ),
  ];
}
