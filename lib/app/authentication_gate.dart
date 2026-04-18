import 'package:flutter/foundation.dart';

/// Minimal contract that lifecycle-aware adapters need from the auth
/// stack: a [Listenable] that exposes the current authentication boolean.
///
/// The concrete `AuthController` already satisfies this interface (it is
/// a `ChangeNotifier` with an `isAuthenticated` getter), so the live wiring
/// is just `gate: context.read<AuthController>()`. Tests can substitute a
/// trivial stub without dragging the entire auth dependency graph.
abstract interface class AuthenticationGate implements Listenable {
  bool get isAuthenticated;
}
