import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Coordinates "back" for shell sections when [Navigator] ancestry does not
/// reflect the nested GoRouter stack (see `AppShellAppBar`).
///
/// Use [navigateShellSectionUp] for both pop and go-to-section-root.

/// True when the shell should not host a Material scaffold drawer because the
/// URL is below the shell section root (for example `/sales/:cardId` or a
/// child path under `/settings/...` that still maps to [AppRoute.settings]).
///
/// This is intentionally narrower than [shellSectionBackVisible], which also
/// treats [Navigator.canPop] as a back signal for the app bar.
bool shellSectionDrawerSuppressed(BuildContext context) {
  final matchedLocation = GoRouterState.of(context).matchedLocation;
  final current = AppRoute.fromLocation(matchedLocation);
  final root = current.shellRootRoute;
  if (root != null && current != root) {
    return true;
  }
  if (root != null &&
      current == root &&
      root.matches(matchedLocation) &&
      !root.matchesExactLocation(matchedLocation)) {
    return true;
  }
  return false;
}

bool shellSectionBackVisible(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    return true;
  }
  final matchedLocation = GoRouterState.of(context).matchedLocation;
  final current = AppRoute.fromLocation(matchedLocation);
  final root = current.shellRootRoute;
  if (root != null && current != root) {
    return true;
  }
  if (root != null &&
      current == root &&
      root.matches(matchedLocation) &&
      !root.matchesExactLocation(matchedLocation)) {
    return true;
  }
  return false;
}

void navigateShellSectionUp(BuildContext context) {
  final router = GoRouter.of(context);
  final matchedLocation = GoRouterState.of(context).matchedLocation;
  final current = AppRoute.fromLocation(matchedLocation);
  final root = current.shellRootRoute;
  if (root != null &&
      current == root &&
      root.matches(matchedLocation) &&
      !root.matchesExactLocation(matchedLocation)) {
    context.goTo(root);
    return;
  }
  if (router.canPop()) {
    context.pop();
    return;
  }
  if (root != null && current != root) {
    context.goTo(root);
  }
}
