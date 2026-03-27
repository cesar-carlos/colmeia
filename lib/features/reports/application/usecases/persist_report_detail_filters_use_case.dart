import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';

class PersistReportDetailFiltersUseCase {
  PersistReportDetailFiltersUseCase(this._reportsRepository);

  final ReportsRepository _reportsRepository;

  Future<void> call({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
  }) {
    return _reportsRepository.savePersistedDetailFilters(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: filters,
    );
  }
}
