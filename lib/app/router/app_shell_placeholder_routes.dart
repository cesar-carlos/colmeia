import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_under_construction_page.dart';
import 'package:go_router/go_router.dart';

typedef _ShellPlaceholderSpec = (AppRoute route, String Function(AppLocalizations) title);

List<RouteBase> buildShellPlaceholderRoutes() {
  final specs = <_ShellPlaceholderSpec>[
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

String _inventoryTitle(AppLocalizations l10n) => l10n.shellNavInventoryLabel;
