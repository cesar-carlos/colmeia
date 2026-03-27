import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_app_bar.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_bottom_nav.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer.dart';
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

    return Scaffold(
      appBar: const AppShellAppBar(),
      drawer: AppShellDrawer(
        currentRoute: currentRoute,
        visibleShellRoutes: visibleShellRoutes,
      ),
      bottomNavigationBar: AppShellBottomNav(
        currentRoute: currentRoute,
        visibleShellRoutes: visibleShellRoutes,
      ),
      body: SafeArea(
        bottom: false,
        child: child,
      ),
    );
  }
}
