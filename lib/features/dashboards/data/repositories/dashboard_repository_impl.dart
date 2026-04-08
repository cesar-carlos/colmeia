import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_local_datasource.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_remote_datasource.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required DashboardLocalDataSource localDataSource,
    required DashboardRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final DashboardLocalDataSource _localDataSource;
  final DashboardRemoteDataSource _remoteDataSource;

  @override
  Future<AppResult<DashboardOverview>> loadOverview({
    required String userId,
    required StoreId storeId,
    DashboardLoadPolicy policy = DashboardLoadPolicy.defaultLoad,
  }) async {
    try {
      final overviewModel = await _remoteDataSource.fetchOverview(
        userId: userId,
        storeId: storeId,
      );
      await _localDataSource.saveOverview(
        userId: userId,
        storeId: storeId,
        overview: overviewModel,
      );
      AppLogger.info(
        'Dashboard overview loaded from remote source',
        context: <String, Object?>{
          'operation': 'loadDashboardOverview',
          'userId': userId,
          'storeId': storeId.value,
          'source': 'remote',
        },
      );

      return Success<DashboardOverview, AppFailure>(overviewModel.toEntity());
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final cachedOverview = await _readCachedOverviewIfAllowed(
        userId: userId,
        storeId: storeId,
        policy: policy,
        statusCode: statusCode,
        error: error,
        stackTrace: stackTrace,
      );
      if (cachedOverview != null) {
        return Success<DashboardOverview, AppFailure>(
          cachedOverview.toEntity(),
        );
      }

      AppLogger.error(
        'Unable to load dashboard overview',
        context: <String, Object?>{
          'operation': 'loadDashboardOverview',
          'userId': userId,
          'storeId': storeId.value,
          'statusCode': statusCode,
          'policy': policy.name,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<DashboardOverview, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load dashboard overview',
          fallbackUserMessage: switch (statusCode) {
            401 => 'Sua sessao expirou. Entre novamente para ver o dashboard.',
            403 =>
              'Sua conta nao tem permissao para visualizar este dashboard.',
            404 =>
              'O dashboard solicitado nao esta disponivel para esta conta.',
            _ => 'Nao foi possivel carregar o dashboard.',
          },
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'storeId': storeId.value,
            'statusCode': statusCode,
            'policy': policy.name,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      final cachedOverview = await _readCachedOverviewIfAllowed(
        userId: userId,
        storeId: storeId,
        policy: policy,
        error: error,
        stackTrace: stackTrace,
      );
      if (cachedOverview != null) {
        return Success<DashboardOverview, AppFailure>(
          cachedOverview.toEntity(),
        );
      }

      AppLogger.error(
        'Unable to load dashboard overview',
        context: <String, Object?>{
          'operation': 'loadDashboardOverview',
          'userId': userId,
          'storeId': storeId.value,
          'policy': policy.name,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<DashboardOverview, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to load dashboard overview',
          fallbackUserMessage: 'Nao foi possivel carregar o dashboard.',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'storeId': storeId.value,
            'policy': policy.name,
          },
        ),
      );
    }
  }

  Future<DashboardOverviewModel?> _readCachedOverviewIfAllowed({
    required String userId,
    required StoreId storeId,
    required DashboardLoadPolicy policy,
    required Object error,
    required StackTrace stackTrace,
    int? statusCode,
  }) async {
    if (!_shouldFallbackToCache(policy: policy, statusCode: statusCode)) {
      return null;
    }

    final cachedOverview = await _localDataSource.readOverview(
      userId: userId,
      storeId: storeId,
    );
    if (cachedOverview == null) {
      return null;
    }

    AppLogger.warning(
      'Dashboard overview fallback to cached data',
      context: <String, Object?>{
        'operation': 'loadDashboardOverview',
        'userId': userId,
        'storeId': storeId.value,
        'source': 'cache',
        'policy': policy.name,
        if (statusCode case final int code) 'statusCode': code,
      },
      error: error,
      stackTrace: stackTrace,
    );
    return cachedOverview;
  }

  bool _shouldFallbackToCache({
    required DashboardLoadPolicy policy,
    int? statusCode,
  }) {
    if (policy == DashboardLoadPolicy.forceRefresh) {
      return false;
    }

    return switch (statusCode) {
      401 || 403 || 404 => false,
      _ => true,
    };
  }
}
