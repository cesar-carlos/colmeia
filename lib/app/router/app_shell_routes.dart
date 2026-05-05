import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/app_shell_placeholder_routes.dart';
import 'package:colmeia/app/router/app_shell_route_observer.dart';
import 'package:colmeia/features/client_agents/presentation/routes/client_agents_routes.dart';
import 'package:colmeia/features/overview/presentation/routes/overview_routes.dart';
import 'package:colmeia/features/sales/presentation/routes/sales_routes.dart';
import 'package:colmeia/features/settings/presentation/routes/settings_routes.dart';
import 'package:colmeia/shared/widgets/app_shell_scaffold.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> buildAppShellRoutes() {
  return <RouteBase>[
    ShellRoute(
      observers: <NavigatorObserver>[appShellRouteObserver],
      builder: (context, state, child) {
        return AppShellScaffold(
          currentLocation: state.uri.path,
          currentRoute: AppRoute.fromLocation(state.matchedLocation),
          child: child,
        );
      },
      routes: <RouteBase>[
        ...buildOverviewRoutes(),
        ...buildSalesRoutes(),
        ...buildShellPlaceholderRoutes(),
        ...buildClientAgentsRoutes(),
        ...buildSettingsRoutes(),
      ],
    ),
  ];
}
