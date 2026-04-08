import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._loadDashboardOverviewUseCase);

  final LoadDashboardOverviewUseCase _loadDashboardOverviewUseCase;

  DashboardOverview? _overview;
  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _requestedOverviewSignature;
  String? _loadedOverviewSignature;
  int _loadGeneration = 0;
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
  bool get isLoading => _isLoadingInitial || _isRefreshing;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isRefreshing => _isRefreshing;
  bool get hasContent => _overview != null;
  String? get errorMessage => _errorMessage;

  /// Schedules [loadOverview] after the current frame when the
  /// user/store pair changes. Safe to call from widget build methods.
  void scheduleOverviewLoadIfNeeded({
    required String userId,
    required StoreId storeId,
  }) {
    final signature = _signatureFor(userId: userId, storeId: storeId);
    if (_requestedOverviewSignature == signature) {
      return;
    }
    _requestedOverviewSignature = signature;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_requestedOverviewSignature != signature) {
        return;
      }
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
    await _loadOverview(
      userId: userId,
      storeId: storeId,
      policy: DashboardLoadPolicy.defaultLoad,
      keepContentVisible: false,
    );
  }

  Future<void> refreshOverview({
    required String userId,
    required StoreId storeId,
  }) async {
    final signature = _signatureFor(userId: userId, storeId: storeId);
    final keepContentVisible =
        _loadedOverviewSignature == signature && _overview != null;
    await _loadOverview(
      userId: userId,
      storeId: storeId,
      policy: DashboardLoadPolicy.forceRefresh,
      keepContentVisible: keepContentVisible,
    );
  }

  Future<void> retryOverview({
    required String userId,
    required StoreId storeId,
  }) async {
    final signature = _signatureFor(userId: userId, storeId: storeId);
    final keepContentVisible =
        _loadedOverviewSignature == signature && _overview != null;
    await _loadOverview(
      userId: userId,
      storeId: storeId,
      policy: keepContentVisible
          ? DashboardLoadPolicy.forceRefresh
          : DashboardLoadPolicy.defaultLoad,
      keepContentVisible: keepContentVisible,
    );
  }

  Future<void> _loadOverview({
    required String userId,
    required StoreId storeId,
    required DashboardLoadPolicy policy,
    required bool keepContentVisible,
  }) async {
    final signature = _signatureFor(userId: userId, storeId: storeId);
    _requestedOverviewSignature = signature;
    final generation = ++_loadGeneration;

    AppLogger.debug(
      'Starting dashboard load in controller',
      context: <String, Object?>{
        'operation': 'loadDashboardOverview',
        'userId': userId,
        'storeId': storeId.value,
        'policy': policy.name,
        'keepContentVisible': keepContentVisible,
      },
    );

    if (keepContentVisible) {
      _isLoadingInitial = false;
      _isRefreshing = true;
    } else {
      _isRefreshing = false;
      _isLoadingInitial = true;
      _overview = null;
      _loadedOverviewSignature = null;
    }
    _errorMessage = null;
    _notifyListenersIfAlive();

    final result = await _loadDashboardOverviewUseCase(
      userId: userId,
      storeId: storeId,
      policy: policy,
    );
    if (_disposed || generation != _loadGeneration) {
      return;
    }

    result.fold(
      (overview) {
        _overview = overview;
        _loadedOverviewSignature = signature;
        AppLogger.info(
          'Dashboard loaded in controller',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'storeId': storeId.value,
            'metrics': overview.summaryMetrics.length,
            'policy': policy.name,
          },
        );
      },
      (failure) {
        if (!keepContentVisible) {
          _overview = null;
          _loadedOverviewSignature = null;
        }
        _errorMessage = failure.displayMessage;
        AppLogger.warning(
          'Dashboard load failed in controller',
          context: <String, Object?>{
            'operation': 'loadDashboardOverview',
            'userId': userId,
            'storeId': storeId.value,
            'policy': policy.name,
            'keepContentVisible': keepContentVisible,
            'technicalMessage': failure.message,
          },
          error: failure.cause ?? failure,
          stackTrace: failure.stackTrace,
        );
      },
    );

    if (keepContentVisible) {
      _isRefreshing = false;
    } else {
      _isLoadingInitial = false;
    }
    _notifyListenersIfAlive();
  }

  String _signatureFor({
    required String userId,
    required StoreId storeId,
  }) {
    return '$userId:${storeId.value}';
  }
}
