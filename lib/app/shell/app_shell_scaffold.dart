import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/shell_section_navigation.dart';
import 'package:colmeia/app/shell/app_shell_app_bar.dart';
import 'package:colmeia/app/shell/app_shell_drawer.dart';
import 'package:colmeia/app/shell/app_shell_rail.dart';
import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/core/layout/app_content_constraint.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/widgets/backgrounds/honeycomb_hex_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    required this.currentLocation,
    required this.currentRoute,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final AppRoute currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visibleShellRoutes = context
        .select<CurrentUserContextController, List<AppRoute>>(
          (controller) => controller.availableShellRoutes,
        );
    final showShellNav = visibleShellRoutes.length > 1;
    // Rail only on desktop; phone + tablet use drawer (not always visible).
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
        // SafeArea here protects the desktop body (rail + app bar + content).
        // The Drawer (mobile path below) has its own SafeArea inside
        // AppShellDrawer — both are intentional and not redundant.
        body: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showShellNav) ...<Widget>[
                AppShellRail(
                  currentLocation: currentLocation,
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
                    AppShellAppBar(
                      matchedLocation: currentLocation,
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
      appBar: AppShellAppBar(matchedLocation: currentLocation),
      drawer:
          showShellNav &&
              !shellSectionDrawerSuppressedForLocation(currentLocation)
          ? AppShellDrawer(
              currentLocation: currentLocation,
              currentRoute: currentRoute,
              visibleShellRoutes: visibleShellRoutes,
            )
          : null,
      body: body,
    );
  }
}
