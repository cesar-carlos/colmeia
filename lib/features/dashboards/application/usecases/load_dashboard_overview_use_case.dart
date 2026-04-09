import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';

class LoadDashboardOverviewUseCase {
  LoadDashboardOverviewUseCase(this._dashboardRepository);

  final DashboardRepository _dashboardRepository;

  Future<AppResult<DashboardOverview>> call({
    required String userId,
    DashboardLoadPolicy policy = DashboardLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
  }) {
    return _dashboardRepository.loadOverview(
      userId: userId,
      policy: policy,
      filter: filter,
    );
  }
}
