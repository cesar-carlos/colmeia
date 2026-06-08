import 'package:colmeia/app/router/app_route_data.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/di/injector_agent_queries.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_sections_use_case.dart';
import 'package:colmeia/features/overview/domain/overview_chart_card_descriptor.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_chart_detail_controller.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/pages/overview_chart_detail_page.dart';
import 'package:colmeia/features/overview/presentation/pages/overview_home_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_under_construction_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void _wireOverviewAgentSqlRelayCancel(AgentQueriesCancelScope scope) {
  wireAgentQueriesCancelScopeHandlers(getIt, scope);
}

/// Route data for the store-scoped overview URL.
///
/// The consolidated overview ignores [storeId] at the page level, but
/// the route is kept to avoid breaking any deep-links or in-app navigation
/// that still targets this path.
final class OverviewStoreRouteData implements AppRouteData {
  OverviewStoreRouteData({
    required this.storeId,
  });

  factory OverviewStoreRouteData.fromState(GoRouterState state) {
    return OverviewStoreRouteData(
      storeId: StoreId(state.pathParameters[storeIdParameter]!),
    );
  }

  static const String storeIdParameter = 'storeId';

  final StoreId storeId;

  @override
  AppRoute get route => AppRoute.dashboardStore;

  @override
  Map<String, String> get pathParameters => <String, String>{
    storeIdParameter: storeId.value,
  };

  @override
  Map<String, dynamic> get queryParameters => const <String, dynamic>{};
}

Widget _buildOverviewHomeRoute(
  BuildContext context,
  GoRouterState state, {
  required bool storeScoped,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<OverviewController>(
        // Factory controller; shared RetryAfterGate comes from GetIt — must
        // not be disposed when this provider is torn down.
        create: (_) => getIt<OverviewController>(),
      ),
    ],
    child: OverviewHomePage(storeScoped: storeScoped),
  );
}

List<RouteBase> buildOverviewRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.dashboardStore.name,
      path: AppRoute.dashboardStore.path,
      builder: (context, state) =>
          _buildOverviewHomeRoute(context, state, storeScoped: true),
    ),
    GoRoute(
      name: AppRoute.dashboardChart.name,
      path: AppRoute.dashboardChart.path,
      builder: (context, state) {
        final chartId = state.pathParameters['chartId'];
        final l10n = AppLocalizations.of(context);
        if (chartId == null || overviewChartCardById(chartId) == null) {
          return AppShellUnderConstructionPage(
            sectionTitle: l10n.shellNavDashboardLabel,
          );
        }
        final initialFilter = state.extra is DashboardFilter
            ? state.extra! as DashboardFilter
            : null;
        return ChangeNotifierProvider<OverviewChartDetailController>(
          create: (_) => OverviewChartDetailController(
            chartId: chartId,
            loadOverviewSectionsUseCase: getIt<LoadOverviewSectionsUseCase>(),
            shellCache: getIt<OverviewShellCache>(),
            initialFilter: initialFilter,
            relayCancelScopeBinder: _wireOverviewAgentSqlRelayCancel,
          ),
          child: OverviewChartDetailPage(chartId: chartId),
        );
      },
    ),
    GoRoute(
      name: AppRoute.dashboard.name,
      path: AppRoute.dashboard.path,
      builder: (context, state) =>
          _buildOverviewHomeRoute(context, state, storeScoped: false),
    ),
  ];
}
