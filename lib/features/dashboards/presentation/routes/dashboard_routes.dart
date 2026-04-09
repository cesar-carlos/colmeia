import 'package:colmeia/app/router/app_route_data.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/presentation/pages/dashboard_home_page.dart';
import 'package:go_router/go_router.dart';

/// Route data for the store-scoped dashboard URL.
///
/// The new consolidated dashboard ignores [storeId] at the page level, but
/// the route is kept to avoid breaking any deep-links or in-app navigation
/// that still targets this path.
final class DashboardStoreRouteData implements AppRouteData {
  DashboardStoreRouteData({
    required this.storeId,
  });

  factory DashboardStoreRouteData.fromState(GoRouterState state) {
    return DashboardStoreRouteData(
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

List<RouteBase> buildDashboardRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.dashboardStore.name,
      path: AppRoute.dashboardStore.path,
      builder: (context, state) => const DashboardHomePage(),
    ),
    GoRoute(
      name: AppRoute.dashboard.name,
      path: AppRoute.dashboard.path,
      builder: (context, state) => const DashboardHomePage(),
    ),
  ];
}
