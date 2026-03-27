import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/domain/entities/reports_overview.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';

class LoadReportsOverviewUseCase {
  LoadReportsOverviewUseCase(this._reportsRepository);

  final ReportsRepository _reportsRepository;

  Future<AppResult<ReportsOverview>> call({
    required String userId,
    required StoreId activeStoreId,
  }) {
    return _reportsRepository.loadOverview(
      userId: userId,
      activeStoreId: activeStoreId,
    );
  }
}
