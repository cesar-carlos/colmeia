import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/presentation/controllers/dashboard_controller.dart';
import 'package:colmeia/features/reports/application/usecases/load_persisted_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/load_report_detail_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/load_reports_overview_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/persist_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/presentation/controllers/report_detail_controller.dart';
import 'package:colmeia/features/reports/presentation/controllers/reports_controller.dart';
import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:get_it/get_it.dart';

void registerInjectorPresentation(GetIt getIt) {
  getIt
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
