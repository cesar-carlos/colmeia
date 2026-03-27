import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/settings/presentation/pages/settings_page.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> buildSettingsRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.settings.name,
      path: AppRoute.settings.path,
      builder: (context, state) {
        return const SettingsPage();
      },
    ),
  ];
}
