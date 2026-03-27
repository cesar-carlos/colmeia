import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:colmeia/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:colmeia/features/reports/domain/entities/report_detail.dart';
import 'package:colmeia/features/reports/domain/entities/reports_overview.dart';
import 'package:colmeia/features/reports/domain/repositories/reports_repository.dart';
import 'package:result_dart/result_dart.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl({
    required ReportsLocalDataSource localDataSource,
    required ReportsRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final ReportsLocalDataSource _localDataSource;
  final ReportsRemoteDataSource _remoteDataSource;

  @override
  Future<AppResult<ReportsOverview>> loadOverview({
    required String userId,
    required StoreId activeStoreId,
  }) async {
    try {
      final overviewModel = await _remoteDataSource.fetchOverview(
        userId: userId,
        activeStoreId: activeStoreId,
      );
      await _localDataSource.saveOverview(
        userId: userId,
        activeStoreId: activeStoreId,
        overview: overviewModel,
      );
      AppLogger.info(
        'Reports overview loaded from remote source',
        context: <String, Object?>{
          'operation': 'loadReportsOverview',
          'userId': userId,
          'activeStoreId': activeStoreId.value,
          'source': 'remote',
        },
      );

      return Success<ReportsOverview, AppFailure>(overviewModel.toEntity());
    } on Object catch (error, stackTrace) {
      final cachedOverview = await _localDataSource.readOverview(
        userId: userId,
        activeStoreId: activeStoreId,
      );
      if (cachedOverview != null) {
        AppLogger.warning(
          'Reports overview fallback to cached data',
          context: <String, Object?>{
            'operation': 'loadReportsOverview',
            'userId': userId,
            'activeStoreId': activeStoreId.value,
            'source': 'cache',
          },
          error: error,
          stackTrace: stackTrace,
        );
        return Success<ReportsOverview, AppFailure>(cachedOverview.toEntity());
      }

      AppLogger.error(
        'Unable to load reports overview',
        context: <String, Object?>{
          'operation': 'loadReportsOverview',
          'userId': userId,
          'activeStoreId': activeStoreId.value,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<ReportsOverview, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load reports overview',
          fallbackUserMessage: 'Nao foi possivel carregar os relatorios.',
          context: <String, Object?>{
            'operation': 'loadReportsOverview',
            'userId': userId,
            'activeStoreId': activeStoreId.value,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<ReportDetail>> loadDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
    int page = 1,
    int pageSize = 2,
  }) async {
    try {
      final detailModel = await _remoteDataSource.fetchDetail(
        userId: userId,
        reportId: reportId,
        storeId: storeId,
        filters: filters,
        page: page,
        pageSize: pageSize,
      );
      await _localDataSource.saveDetail(
        userId: userId,
        reportId: reportId,
        storeId: storeId,
        detail: detailModel,
        filters: filters,
        page: page,
        pageSize: pageSize,
      );
      AppLogger.info(
        'Report detail loaded from remote source',
        context: <String, Object?>{
          'operation': 'loadReportDetail',
          'userId': userId,
          'reportId': reportId.value,
          'storeId': storeId.value,
          'page': page,
          'source': 'remote',
        },
      );

      return Success<ReportDetail, AppFailure>(detailModel.toEntity());
    } on Object catch (error, stackTrace) {
      final cachedDetail = await _localDataSource.readDetail(
        userId: userId,
        reportId: reportId,
        storeId: storeId,
        filters: filters,
        page: page,
        pageSize: pageSize,
      );
      if (cachedDetail != null) {
        AppLogger.warning(
          'Report detail fallback to cached data',
          context: <String, Object?>{
            'operation': 'loadReportDetail',
            'userId': userId,
            'reportId': reportId.value,
            'storeId': storeId.value,
            'page': page,
            'source': 'cache',
          },
          error: error,
          stackTrace: stackTrace,
        );
        return Success<ReportDetail, AppFailure>(cachedDetail.toEntity());
      }

      AppLogger.error(
        'Unable to load report detail',
        context: <String, Object?>{
          'operation': 'loadReportDetail',
          'userId': userId,
          'reportId': reportId.value,
          'storeId': storeId.value,
          'page': page,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<ReportDetail, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load report detail',
          fallbackUserMessage:
              'Nao foi possivel carregar os detalhes do relatorio.',
          context: <String, Object?>{
            'operation': 'loadReportDetail',
            'userId': userId,
            'reportId': reportId.value,
            'storeId': storeId.value,
            'page': page,
          },
        ),
      );
    }
  }

  @override
  Future<Map<String, Object?>> readPersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  }) {
    return _localDataSource.readPersistedDetailFilters(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
    );
  }

  @override
  Future<void> savePersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
  }) {
    return _localDataSource.savePersistedDetailFilters(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: filters,
    );
  }
}
