import 'package:colmeia/core/di/injector_auth.dart';
import 'package:colmeia/core/di/injector_core.dart';
import 'package:colmeia/core/di/injector_dashboards_reports.dart';
import 'package:colmeia/core/di/injector_presentation.dart';
import 'package:colmeia/core/di/injector_user_context.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  if (getIt.isRegistered<CurrentUserContextController>()) {
    return;
  }

  await registerInjectorCore(getIt);
  registerInjectorAuth(getIt);
  registerInjectorUserContext(getIt);
  registerInjectorDashboardsAndReports(getIt);
  registerInjectorPresentation(getIt);
}

/// Clears all registrations. Intended for tests that need a fresh service
/// locator; do not call from production code paths.
@visibleForTesting
Future<void> resetDependenciesForTesting() async {
  await getIt.reset();
}
