import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/dev/fake_backend/fake_identity_backend_store.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_local_datasource.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_remote_datasource.dart';
import 'package:colmeia/features/dashboards/data/repositories/dashboard_repository_impl.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:colmeia/features/reports/application/usecases/load_persisted_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/load_report_detail_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/load_reports_overview_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/persist_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:colmeia/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:colmeia/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

void registerInjectorDashboardsAndReports(GetIt getIt) {
  getIt
    ..registerLazySingleton<DashboardLocalDataSource>(
      () => DashboardLocalDataSource(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<DashboardRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeDashboardRemoteDataSource(
              getIt<FakeIdentityBackendStore>(),
            )
          : ApiDashboardRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<ReportsLocalDataSource>(
      () => ReportsLocalDataSource(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<ReportsRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeReportsRemoteDataSource(
              getIt<FakeIdentityBackendStore>(),
            )
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
    );
}
