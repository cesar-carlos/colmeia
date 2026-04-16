import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_under_construction_page.dart';
import 'package:go_router/go_router.dart';

typedef _ShellPlaceholderSpec = (AppRoute route, String Function(AppLocalizations) title);

List<RouteBase> buildShellPlaceholderRoutes() {
  final specs = <_ShellPlaceholderSpec>[
    (AppRoute.sales, _salesTitle),
    (AppRoute.returns, _returnsTitle),
    (AppRoute.finance, _financeTitle),
    (AppRoute.purchases, _purchasesTitle),
    (AppRoute.inventory, _inventoryTitle),
  ];

  return specs
      .map(
        (spec) => GoRoute(
          name: spec.$1.name,
          path: spec.$1.path,
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return AppShellUnderConstructionPage(
              sectionTitle: spec.$2(l10n),
            );
          },
        ),
      )
      .toList(growable: false);
}

String _salesTitle(AppLocalizations l10n) => l10n.shellNavSalesLabel;

String _returnsTitle(AppLocalizations l10n) => l10n.shellNavReturnsLabel;

String _financeTitle(AppLocalizations l10n) => l10n.shellNavFinanceLabel;

String _purchasesTitle(AppLocalizations l10n) => l10n.shellNavPurchasesLabel;

String _inventoryTitle(AppLocalizations l10n) => l10n.shellNavInventoryLabel;
