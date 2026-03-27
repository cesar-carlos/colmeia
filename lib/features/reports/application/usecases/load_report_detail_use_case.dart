import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/domain/entities/report_detail.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';

class LoadReportDetailUseCase {
  LoadReportDetailUseCase(this._reportsRepository);

  final ReportsRepository _reportsRepository;

  Future<AppResult<ReportDetail>> call({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
    int page = 1,
    int pageSize = 2,
  }) {
    return _reportsRepository.loadDetail(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: filters,
      page: page,
      pageSize: pageSize,
    );
  }
}
