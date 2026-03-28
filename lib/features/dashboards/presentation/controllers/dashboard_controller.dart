import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._loadDashboardOverviewUseCase);

  final LoadDashboardOverviewUseCase _loadDashboardOverviewUseCase;

  DashboardOverview? _overview;
  bool _isLoading = false;
  String? _errorMessage;
  String? _overviewLoadSignature;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notifyListenersIfAlive() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  DashboardOverview? get overview => _overview;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Schedules [loadOverview] after the current frame when the
  /// user/store pair changes. Safe to call from widget build methods.
  void scheduleOverviewLoadIfNeeded({
    required String userId,
    required StoreId storeId,
  }) {
    final signature = '$userId:${storeId.value}';
    if (_overviewLoadSignature == signature) {
      return;
    }
    _overviewLoadSignature = signature;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(
        loadOverview(
          userId: userId,
          storeId: storeId,
        ),
      );
    });
  }

  Future<void> loadOverview({
    required String userId,
    required StoreId storeId,
  }) async {
    AppLogger.debug(
      'Starting dashboard load in controller',
      context: <String, Object?>{
        'operation': 'loadDashboardOverview',
        'userId': userId,
        'storeId': storeId.value,
      },
    );
    _isLoading = true;
    _errorMessage = null;
    _notifyListenersIfAlive();

    final result = await _loadDashboardOverviewUseCase(
      userId: userId,
      storeId: storeId,
    );
    if (_disposed) {
      return;
    }
    result.fold(
      (overview) {
        _overview = overview;
        AppLogger.info(
          'Dashboard loaded in controller',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'storeId': storeId.value,
            'metrics': overview.summaryMetrics.length,
          },
        );
      },
      (failure) {
        _overview = null;
        _errorMessage = failure.displayMessage;
        AppLogger.warning(
          'Dashboard load failed in controller',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'storeId': storeId.value,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      },
    );

    _isLoading = false;
    _notifyListenersIfAlive();
  }
}
