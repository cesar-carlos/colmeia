import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/domain/entities/report_detail.dart';
import 'package:colmeia/features/reports/domain/entities/reports_overview.dart';

abstract interface class ReportsRepository {
  Future<AppResult<ReportsOverview>> loadOverview({
    required String userId,
    required StoreId activeStoreId,
  });

  Future<AppResult<ReportDetail>> loadDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
    int page = 1,
    int pageSize = 2,
  });

  Future<Map<String, Object?>> readPersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  });

  Future<void> savePersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
  });
}
