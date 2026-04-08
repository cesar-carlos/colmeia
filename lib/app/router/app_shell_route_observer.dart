import 'package:flutter/material.dart';

/// Observes the app shell navigator (see `ShellRoute.observers` in go_router).
///
/// Feature pages can mix in `RouteAware` and react when a child route is
/// popped (e.g. refresh the agents list after closing agent detail).
final RouteObserver<ModalRoute<void>> appShellRouteObserver =
    RouteObserver<ModalRoute<void>>();
