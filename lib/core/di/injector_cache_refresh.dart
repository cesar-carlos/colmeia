import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/di/injector_cache_refresh_reports.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/agent_queries/application/sync/cache_refresh_coordinator.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/cache_refresh_lock.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/catalog_cache_refresh_presence.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/local_cache_refresh_schedule_repository.dart';
import 'package:colmeia/features/agent_queries/data/scheduling/scheduled_report_refresh_executor.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/agent_queries/presentation/controllers/cache_refresh_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_approved_agents_repository.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:get_it/get_it.dart';

void registerInjectorCacheRefresh(GetIt getIt) {
  getIt.registerLazySingleton<CacheRefreshLock>(createCacheRefreshLock);
  getIt.registerLazySingleton<CacheRefreshScheduleRepository>(
    () => LocalCacheRefreshScheduleRepository(
      getIt<AppCacheStore>(),
      getIt<CacheRefreshLock>(),
      isAuthorized: (user) => getIt<AuthController>().session?.userId == user,
    ),
  );
  getIt.registerLazySingleton<CacheRefreshPresence>(
    () => CatalogCacheRefreshPresence(getIt<ClientApprovedAgentsRepository>()),
  );
  getIt.registerLazySingleton<RegisteredReportRefreshExecutor>(
    () => createReportRefreshExecutor(getIt),
  );
  getIt.registerLazySingleton<CacheRefreshCoordinator>(
    () => CacheRefreshCoordinator(
      repository: getIt<CacheRefreshScheduleRepository>(),
      executor: getIt<RegisteredReportRefreshExecutor>(),
      presence: getIt<CacheRefreshPresence>(),
      lock: getIt<CacheRefreshLock>(),
      online: () => getIt<PwaPlatform>().online,
      onSessionRejected: () => getIt<AuthSessionEvents>().notifyInvalidated(),
      onWorkStarted: () => getIt<PwaPlatform>().beginWork(),
      onWorkFinished: () => getIt<PwaPlatform>().endWork(),
      onRevoked: (user, agent) =>
          getIt<PwaPackageService>().remove(user, agent),
    ),
    dispose: (value) => value.dispose(),
  );
  getIt.registerFactory<CacheRefreshController>(
    () => CacheRefreshController(
      getIt<CacheRefreshCoordinator>(),
      getIt<RegisteredReportRefreshExecutor>().reports,
      getIt<ClientApprovedAgentsRepository>(),
      () => getIt<AuthController>().session?.userId,
    ),
  );
}
