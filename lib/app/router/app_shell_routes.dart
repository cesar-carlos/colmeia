import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/dashboards/presentation/routes/dashboard_routes.dart';
import 'package:colmeia/features/reports/presentation/routes/report_routes.dart';
import 'package:colmeia/features/settings/presentation/routes/settings_routes.dart';
import 'package:colmeia/shared/widgets/app_shell_scaffold.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> buildAppShellRoutes() {
  return <RouteBase>[
    ShellRoute(
      builder: (context, state, child) {
        return AppShellScaffold(
          currentRoute: AppRoute.fromLocation(state.matchedLocation),
          child: child,
        );
      },
      routes: <RouteBase>[
        ...buildDashboardRoutes(),
        ...buildReportRoutes(),
        ...buildSettingsRoutes(),
      ],
    ),
  ];
}
