import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';

// ignore: one_member_abstracts, this contract should grow with cache and sync operations
abstract interface class DashboardRepository {
  Future<AppResult<DashboardOverview>> loadOverview({
    required String userId,
    required StoreId storeId,
  });
}
