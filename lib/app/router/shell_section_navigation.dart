import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Coordinates "back" for shell sections when [Navigator] ancestry does not
/// reflect the nested GoRouter stack (see `AppShellAppBar`).
///
/// Use [navigateShellSectionUp] for both pop and go-to-section-root.
///
/// Prefer location-based helpers ([shellSectionBackVisibleForLocation],
/// [shellSectionDrawerSuppressedForLocation]) from `ShellRoute.builder` state.
/// Do not call `GoRouterState.of` from the shell chrome: during auth redirects
/// (e.g. sign-out) the shell can rebuild while still under [GoRouter] but
/// outside a `RouteBase.builder` subtree.

/// True when [matchedLocation] is below the shell section root (for example
/// `/sales/:cardId` or a child path under `/settings/...` that still maps to
/// [AppRoute.settings]).
bool shellSectionDrawerSuppressedForLocation(String matchedLocation) {
  return _isBelowShellSectionRoot(matchedLocation);
}

/// True when the shell should not host a Material scaffold drawer because the
/// URL is below the shell section root.
///
/// This is intentionally narrower than [shellSectionBackVisible], which also
/// treats [GoRouter.canPop] as a back signal for the app bar.
bool shellSectionDrawerSuppressed(BuildContext context) {
  final matchedLocation = _shellMatchedLocation(context);
  if (matchedLocation == null) {
    return false;
  }
  return shellSectionDrawerSuppressedForLocation(matchedLocation);
}

bool shellSectionBackVisibleForLocation(
  String matchedLocation, {
  required bool canPop,
}) {
  if (canPop) {
    return true;
  }
  return _isBelowShellSectionRoot(matchedLocation);
}

bool shellSectionBackVisible(
  BuildContext context, {
  String? matchedLocation,
}) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return false;
  }
  final location = matchedLocation ?? _shellMatchedLocation(context);
  if (location == null) {
    return false;
  }
  return shellSectionBackVisibleForLocation(
    location,
    canPop: router.canPop(),
  );
}

void navigateShellSectionUp(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return;
  }
  final matchedLocation = _shellMatchedLocation(context);
  if (matchedLocation == null) {
    return;
  }
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

/// Resolves the current matched location without [GoRouterState.of].
///
/// Uses [GoRouter.state], which remains readable while shell chrome rebuilds
/// during redirects that have already dropped the route-state registry.
String? _shellMatchedLocation(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return null;
  }
  return router.state.matchedLocation;
}

bool _isBelowShellSectionRoot(String matchedLocation) {
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
