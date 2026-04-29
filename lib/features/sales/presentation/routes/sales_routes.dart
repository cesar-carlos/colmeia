import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_card_placeholder_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_hub_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_rank_lucro_page.dart';
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
      name: AppRoute.salesCard.name,
      path: AppRoute.salesCard.path,
      builder: (context, state) {
        final cardId = state.pathParameters['cardId'];
        if (cardId == null) {
          final l10n = AppLocalizations.of(context);
          return AppShellUnderConstructionPage(
            sectionTitle: l10n.shellNavSalesLabel,
          );
        }

        final descriptor = findSalesCardById(cardId);
        if (descriptor == null) {
          final l10n = AppLocalizations.of(context);
          return AppShellUnderConstructionPage(
            sectionTitle: l10n.shellNavSalesLabel,
          );
        }

        if (cardId == 'produto_rank_lucro') {
          return const SalesProdutoRankLucroPage();
        }

        return SalesCardPlaceholderPage(cardDescriptor: descriptor);
      },
    ),
  ];
}
