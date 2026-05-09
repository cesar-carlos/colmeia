import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Coordinates "back" for shell sections when [Navigator] ancestry does not
/// reflect the nested GoRouter stack (see `AppShellAppBar`).
///
/// Use [navigateShellSectionUp] for both pop and go-to-section-root.
bool shellSectionBackVisible(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    return true;
  }
  final current = AppRoute.fromLocation(
    GoRouterState.of(context).matchedLocation,
  );
  final root = current.shellRootRoute;
  return root != null && current != root;
}

void navigateShellSectionUp(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    context.pop();
    return;
  }
  final current = AppRoute.fromLocation(
    GoRouterState.of(context).matchedLocation,
  );
  final root = current.shellRootRoute;
  if (root != null && current != root) {
    context.goTo(root);
  }
}
