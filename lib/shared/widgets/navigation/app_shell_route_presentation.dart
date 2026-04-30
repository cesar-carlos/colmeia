import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AppShellRoutePresentation {
  const AppShellRoutePresentation({
    required this.route,
    required this.label,
    this.subtitle,
  });

  final AppRoute route;
  final String label;
  final String? subtitle;
}

String _shellRouteLabel(AppRoute route, AppLocalizations l10n) {
  return switch (route) {
    AppRoute.unmatched => route.title,
    AppRoute.dashboard ||
    AppRoute.dashboardStore => l10n.shellNavDashboardLabel,
    AppRoute.sales ||
    AppRoute.salesCard => l10n.shellNavSalesLabel,
    AppRoute.returns => l10n.shellNavReturnsLabel,
    AppRoute.finance => l10n.shellNavFinanceLabel,
    AppRoute.purchases => l10n.shellNavPurchasesLabel,
    AppRoute.inventory => l10n.shellNavInventoryLabel,
    AppRoute.settings => l10n.shellNavSettingsLabel,
    AppRoute.agents => l10n.shellNavAgentsLabel,
    AppRoute.agentsDetail => l10n.shellNavAgentsLabel,
    AppRoute.chartFullscreen => route.title,
    AppRoute.login ||
    AppRoute.register ||
    AppRoute.registrationStatus ||
    AppRoute.passwordRecovery ||
    AppRoute.passwordRecoveryReset => route.title,
  };
}

String? _shellRouteSubtitle(AppRoute route, AppLocalizations l10n) {
  return switch (route) {
    AppRoute.unmatched => null,
    AppRoute.dashboard ||
    AppRoute.dashboardStore => l10n.shellNavDashboardSubtitle,
    AppRoute.sales ||
    AppRoute.salesCard => l10n.shellNavSalesSubtitle,
    AppRoute.returns => l10n.shellNavReturnsSubtitle,
    AppRoute.finance => l10n.shellNavFinanceSubtitle,
    AppRoute.purchases => l10n.shellNavPurchasesSubtitle,
    AppRoute.inventory => l10n.shellNavInventorySubtitle,
    AppRoute.settings => l10n.shellNavSettingsSubtitle,
    AppRoute.agents => l10n.shellNavAgentsSubtitle,
    AppRoute.agentsDetail => null,
    AppRoute.chartFullscreen => null,
    AppRoute.login ||
    AppRoute.register ||
    AppRoute.registrationStatus ||
    AppRoute.passwordRecovery ||
    AppRoute.passwordRecoveryReset => null,
  };
}

AppShellRoutePresentation appShellRoutePresentation(
  AppRoute route,
  AppLocalizations l10n,
) {
  return AppShellRoutePresentation(
    route: route,
    label: _shellRouteLabel(route, l10n),
    subtitle: _shellRouteSubtitle(route, l10n),
  );
}

List<AppShellRoutePresentation> buildAppShellRoutePresentations(
  Iterable<AppRoute> routes,
  AppLocalizations l10n,
) {
  return routes
      .map((r) => appShellRoutePresentation(r, l10n))
      .toList(
        growable: false,
      );
}

String appShellRouteLabel(AppRoute route, AppLocalizations l10n) {
  return _shellRouteLabel(route, l10n);
}

String? appShellRouteSubtitle(AppRoute route, AppLocalizations l10n) {
  return _shellRouteSubtitle(route, l10n);
}

IconData appShellRouteIcon(AppRoute route, {required bool selected}) {
  return selected
      ? route.selectedNavigationIcon
      : route.unselectedNavigationIcon;
}
