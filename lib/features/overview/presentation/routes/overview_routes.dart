import 'package:colmeia/app/router/app_route_data.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/overview/presentation/pages/overview_home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

Widget _buildOverviewHomeRoute(BuildContext context, GoRouterState state) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<OverviewController>(
        create: (_) => getIt<OverviewController>(),
      ),
    ],
    child: const OverviewHomePage(),
  );
}

List<RouteBase> buildOverviewRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.dashboardStore.name,
      path: AppRoute.dashboardStore.path,
      builder: _buildOverviewHomeRoute,
    ),
    GoRoute(
      name: AppRoute.dashboard.name,
      path: AppRoute.dashboard.path,
      builder: _buildOverviewHomeRoute,
    ),
  ];
}
