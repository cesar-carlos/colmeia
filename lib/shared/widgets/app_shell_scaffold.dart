import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    required this.currentRoute,
    required this.child,
    super.key,
  });

  final AppRoute currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final userContextController = context.watch<CurrentUserContextController>();
    final visibleShellRoutes = userContextController.availableShellRoutes;
    final selectedIndex = visibleShellRoutes.indexWhere(
      (route) => route.shellIndex == currentRoute.shellIndex,
    );

    return Scaffold(
      appBar: AppBar(title: Text(currentRoute.title)),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
        onDestinationSelected: (index) => _onSelectDestination(context, index),
        destinations: _destinationsForRoutes(visibleShellRoutes),
      ),
    );
  }

  void _onSelectDestination(BuildContext context, int index) {
    final route = context
        .read<CurrentUserContextController>()
        .availableShellRoutes[index];
    if (route == currentRoute) {
      return;
    }

    context.goTo(route);
  }

  List<NavigationDestination> _destinationsForRoutes(List<AppRoute> routes) {
    return routes.map(_destinationForRoute).toList();
  }

  NavigationDestination _destinationForRoute(AppRoute route) {
    switch (route) {
      case AppRoute.dashboard:
        return const NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard),
          label: 'Dashboard',
        );
      case AppRoute.reports:
        return const NavigationDestination(
          icon: Icon(Icons.assessment_outlined),
          selectedIcon: Icon(Icons.assessment),
          label: 'Relatorios',
        );
      case AppRoute.settings:
        return const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Ajustes',
        );
      case AppRoute.login:
      case AppRoute.register:
      case AppRoute.dashboardStore:
      case AppRoute.reportDetail:
        throw UnsupportedError('Route is not a shell destination');
    }
  }
}
