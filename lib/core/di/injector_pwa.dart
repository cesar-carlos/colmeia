import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_vendas_municipio_filial_periodo_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/scheduling/cache_refresh_ports.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/pwa/application/pwa_package_service.dart';
import 'package:colmeia/features/pwa/data/offline_package_store.dart';
import 'package:colmeia/features/pwa/data/pwa_authorization_gateway.dart';
import 'package:colmeia/features/pwa/data/pwa_dataset_loader.dart';
import 'package:colmeia/features/pwa/data/pwa_push_client.dart';
import 'package:colmeia/features/pwa/domain/push_subscriptions.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerInjectorPwa(GetIt getIt) {
  getIt.registerLazySingleton<PushSubscriptions>(
    () => !getIt<PwaPlatform>().supported
        ? InactivePushSubscriptions()
        : PwaPushClient(
            getIt<PwaPlatform>(),
            getIt<Dio>(),
            getIt<SharedPreferences>(),
          ),
  );
  getIt.registerLazySingleton<OfflinePackageStore>(
    () => OfflinePackageStore(getIt<AppCacheStore>()),
  );
  getIt.registerLazySingleton<PwaPackageService>(
    () => PwaPackageService(
      platform: getIt<PwaPlatform>(),
      selectionLock: getIt.isRegistered<CacheRefreshLock>()
          ? getIt<CacheRefreshLock>()
          : null,
      onRevoked: getIt<AuthSessionEvents>().notifyInvalidated,
      store: getIt<OfflinePackageStore>(),
      cache: getIt<AppCacheStore>(),
      authorization: PwaAuthorizationGateway(getIt<Dio>()),
      loader: PwaDatasetLoader(
        getIt<OverviewRepositoryImpl>(),
        getIt<UserContextRemoteDataSource>(),
        getIt<AgentClientTokenReader>(),
        getIt<LoadResumoTotalVendasMunicipioFilialPeriodoUseCase>(),
      ).call,
    ),
  );
}
