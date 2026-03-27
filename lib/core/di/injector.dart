import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/core/storage/app_database.dart';
import 'package:colmeia/core/storage/session_storage.dart';
import 'package:colmeia/features/auth/application/usecases/login_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/logout_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/register_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/restore_session_use_case.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/fake_auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:colmeia/features/auth/domain/repositories/auth_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_local_datasource.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_remote_datasource.dart';
import 'package:colmeia/features/dashboards/data/repositories/dashboard_repository_impl.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:colmeia/features/dashboards/presentation/controllers/dashboard_controller.dart';
import 'package:colmeia/features/reports/application/usecases/load_persisted_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/load_report_detail_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/load_reports_overview_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/persist_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:colmeia/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:colmeia/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';
import 'package:colmeia/features/reports/presentation/controllers/report_detail_controller.dart';
import 'package:colmeia/features/reports/presentation/controllers/reports_controller.dart';
import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_local_datasource.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/features/user_context/data/repositories/user_context_repository_impl.dart';
import 'package:colmeia/features/user_context/domain/repositories/user_context_repository.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  if (getIt.isRegistered<CurrentUserContextController>()) {
    return;
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<AppUserPreferencesStore>(
      AppUserPreferencesStore(sharedPreferences),
    )
    ..registerLazySingleton<Dio>(AppDioClient.create)
    ..registerLazySingleton<FlutterSecureStorage>(FlutterSecureStorage.new)
    ..registerLazySingleton<SessionStorage>(
      () => SessionStorage(getIt<FlutterSecureStorage>()),
    )
    ..registerLazySingleton<FakeIdentityBackendStore>(
      () => FakeIdentityBackendStore(getIt<SessionStorage>()),
    )
    ..registerLazySingleton<AppDatabase>(AppDatabase.new)
    ..registerLazySingleton<AppCacheStore>(
      () => AppCacheStore(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSource(
        sessionStorage: getIt<SessionStorage>(),
      ),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeAuthRemoteDataSource(getIt<FakeIdentityBackendStore>())
          : ApiAuthRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<UserContextLocalDataSource>(
      () => UserContextLocalDataSource(getIt<SessionStorage>()),
    )
    ..registerLazySingleton<UserContextRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeUserContextRemoteDataSource(getIt<FakeIdentityBackendStore>())
          : ApiUserContextRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        localDataSource: getIt<AuthLocalDataSource>(),
        remoteDataSource: getIt<AuthRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<UserContextRepository>(
      () => UserContextRepositoryImpl(
        localDataSource: getIt<UserContextLocalDataSource>(),
        remoteDataSource: getIt<UserContextRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<DashboardLocalDataSource>(
      () => DashboardLocalDataSource(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<DashboardRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeDashboardRemoteDataSource(getIt<FakeIdentityBackendStore>())
          : ApiDashboardRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<ReportsLocalDataSource>(
      () => ReportsLocalDataSource(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<ReportsRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeReportsRemoteDataSource(getIt<FakeIdentityBackendStore>())
          : ApiReportsRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(
        localDataSource: getIt<DashboardLocalDataSource>(),
        remoteDataSource: getIt<DashboardRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<ReportsRepository>(
      () => ReportsRepositoryImpl(
        localDataSource: getIt<ReportsLocalDataSource>(),
        remoteDataSource: getIt<ReportsRemoteDataSource>(),
      ),
    )
    ..registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<RestoreSessionUseCase>(
      () => RestoreSessionUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<RegisterUseCase>(
      () => RegisterUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<LogoutUseCase>(
      () => LogoutUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<LoadCurrentUserContextUseCase>(
      () => LoadCurrentUserContextUseCase(getIt<UserContextRepository>()),
    )
    ..registerLazySingleton<PersistActiveStoreUseCase>(
      () => PersistActiveStoreUseCase(getIt<UserContextRepository>()),
    )
    ..registerLazySingleton<ClearActiveStoreUseCase>(
      () => ClearActiveStoreUseCase(getIt<UserContextRepository>()),
    )
    ..registerLazySingleton<LoadDashboardOverviewUseCase>(
      () => LoadDashboardOverviewUseCase(getIt<DashboardRepository>()),
    )
    ..registerLazySingleton<LoadReportsOverviewUseCase>(
      () => LoadReportsOverviewUseCase(getIt<ReportsRepository>()),
    )
    ..registerLazySingleton<LoadReportDetailUseCase>(
      () => LoadReportDetailUseCase(getIt<ReportsRepository>()),
    )
    ..registerLazySingleton<LoadPersistedReportDetailFiltersUseCase>(
      () => LoadPersistedReportDetailFiltersUseCase(getIt<ReportsRepository>()),
    )
    ..registerLazySingleton<PersistReportDetailFiltersUseCase>(
      () => PersistReportDetailFiltersUseCase(getIt<ReportsRepository>()),
    )
    ..registerLazySingleton<AuthController>(
      () => AuthController(
        loginUseCase: getIt<LoginUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        registerUseCase: getIt<RegisterUseCase>(),
        restoreSessionUseCase: getIt<RestoreSessionUseCase>(),
      ),
    )
    ..registerFactory<CurrentUserContextController>(
      () => CurrentUserContextController(
        authController: getIt<AuthController>(),
        loadCurrentUserContextUseCase: getIt<LoadCurrentUserContextUseCase>(),
        persistActiveStoreUseCase: getIt<PersistActiveStoreUseCase>(),
        clearActiveStoreUseCase: getIt<ClearActiveStoreUseCase>(),
      ),
    )
    ..registerFactory<DashboardController>(
      () => DashboardController(getIt<LoadDashboardOverviewUseCase>()),
    )
    ..registerFactory<ReportsController>(
      () => ReportsController(getIt<LoadReportsOverviewUseCase>()),
    )
    ..registerFactory<ReportDetailController>(
      () => ReportDetailController(
        getIt<LoadReportDetailUseCase>(),
        getIt<LoadPersistedReportDetailFiltersUseCase>(),
        getIt<PersistReportDetailFiltersUseCase>(),
      ),
    );
}
