import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/layout/app_content_constraint.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/widgets/backgrounds/honeycomb_hex_background.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_app_bar.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_drawer.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_rail.dart';
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
    final visibleShellRoutes = context
        .select<CurrentUserContextController, List<AppRoute>>(
          (controller) => controller.availableShellRoutes,
        );
    final showShellNav = visibleShellRoutes.length > 1;
    final useRail = AppBreakpoints.useRail(context);

    final body = HoneycombHexBackground(
      child: SafeArea(
        bottom: false,
        child: AppContentConstraint(child: child),
      ),
    );

    if (useRail) {
      final railDividerColor = Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.22);

      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showShellNav) ...<Widget>[
                AppShellRail(
                  currentRoute: currentRoute,
                  visibleShellRoutes: visibleShellRoutes,
                ),
                SizedBox(
                  width: 1,
                  child: ColoredBox(color: railDividerColor),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const AppShellAppBar(
                      primary: false,
                      showBrandTitle: false,
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const AppShellAppBar(),
      drawer: showShellNav
          ? AppShellDrawer(
              currentRoute: currentRoute,
              visibleShellRoutes: visibleShellRoutes,
            )
          : null,
      body: body,
    );
  }
}
