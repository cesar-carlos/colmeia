import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';

class LoadPersistedReportDetailFiltersUseCase {
  LoadPersistedReportDetailFiltersUseCase(this._reportsRepository);

  final ReportsRepository _reportsRepository;

  Future<Map<String, Object?>> call({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  }) {
    return _reportsRepository.readPersistedDetailFilters(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
    );
  }
}
