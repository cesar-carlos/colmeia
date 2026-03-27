import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/application/usecases/load_persisted_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/load_report_detail_use_case.dart';
import 'package:colmeia/features/reports/application/usecases/persist_report_detail_filters_use_case.dart';
import 'package:colmeia/features/reports/domain/entities/report_detail.dart';
import 'package:flutter/foundation.dart';

class ReportDetailController extends ChangeNotifier {
  ReportDetailController(
    this._loadReportDetailUseCase,
    this._loadPersistedReportDetailFiltersUseCase,
    this._persistReportDetailFiltersUseCase,
  );

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

  final LoadReportDetailUseCase _loadReportDetailUseCase;
  final LoadPersistedReportDetailFiltersUseCase
  _loadPersistedReportDetailFiltersUseCase;
  final PersistReportDetailFiltersUseCase _persistReportDetailFiltersUseCase;

  ReportDetail? _detail;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, Object?> _filters = const <String, Object?>{};
  String? _loadedScopeKey;

  ReportDetail? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, Object?> get filters => _filters;
  int get currentPage => _detail?.pageInfo.currentPage ?? 1;
  int get totalPages => _detail?.pageInfo.totalPages ?? 1;
  bool get canLoadPreviousPage => currentPage > 1;
  bool get canLoadNextPage => currentPage < totalPages;

  Future<void> initialize({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  }) async {
    final scopeKey = '$userId:${reportId.value}:${storeId.value}';
    if (_loadedScopeKey == scopeKey && (_detail != null || _isLoading)) {
      return;
    }

    _loadedScopeKey = scopeKey;
    _filters = await _loadPersistedReportDetailFiltersUseCase(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
    );
    if (_disposed) {
      return;
    }

    await loadDetail(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: _filters,
    );
  }

  Future<void> loadDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    Map<String, Object?>? filters,
    int page = 1,
  }) async {
    final effectiveFilters = filters ?? _filters;

    AppLogger.debug(
      'Starting report detail load in controller',
      context: <String, Object?>{
        'operation': 'loadReportDetail',
        'userId': userId,
        'reportId': reportId.value,
        'storeId': storeId.value,
        'page': page,
      },
    );
    _isLoading = true;
    _errorMessage = null;
    _notifyListenersIfAlive();

    final result = await _loadReportDetailUseCase(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: effectiveFilters,
      page: page,
    );
    if (_disposed) {
      return;
    }
    result.fold(
      (detail) {
        _detail = detail;
        _filters = effectiveFilters;
        AppLogger.info(
          'Report detail loaded in controller',
          context: <String, Object?>{
            'operation': 'loadReportDetail',
            'userId': userId,
            'reportId': reportId.value,
            'storeId': storeId.value,
            'page': page,
            'rows': detail.rows.length,
          },
        );
      },
      (failure) {
        _detail = null;
        _errorMessage = failure.displayMessage;
        AppLogger.warning(
          'Report detail load failed in controller',
          context: <String, Object?>{
            'operation': 'loadReportDetail',
            'userId': userId,
            'reportId': reportId.value,
            'storeId': storeId.value,
            'page': page,
          },
        );
      },
    );

    _isLoading = false;
    _notifyListenersIfAlive();
  }

  Future<void> applyFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
  }) async {
    final normalizedFilters = <String, Object?>{
      ..._filters,
      ...filters,
      'seller': (filters['seller'] as String?)?.trim() ?? '',
    };
    final validationFailure = _validateFiltersAgainstCurrentParameters(
      normalizedFilters,
    );
    if (validationFailure != null) {
      _errorMessage = validationFailure.displayMessage;
      AppLogger.warning(
        'Report detail filters rejected by controller validation',
        context: <String, Object?>{
          'operation': 'applyReportDetailFilters',
          'reportId': reportId.value,
          'storeId': storeId.value,
          'blocked': normalizedFilters.keys.join(','),
        },
      );
      _notifyListenersIfAlive();
      return;
    }
    await _persistReportDetailFiltersUseCase(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: normalizedFilters,
    );
    if (_disposed) {
      return;
    }
    await loadDetail(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: normalizedFilters,
    );
  }

  Future<void> clearFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  }) async {
    const clearedFilters = <String, Object?>{};
    await _persistReportDetailFiltersUseCase(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: clearedFilters,
    );
    if (_disposed) {
      return;
    }
    await loadDetail(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: clearedFilters,
    );
  }

  Future<void> loadNextPage({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  }) {
    return loadDetail(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: _filters,
      page: currentPage + 1,
    );
  }

  Future<void> loadPreviousPage({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  }) {
    return loadDetail(
      userId: userId,
      reportId: reportId,
      storeId: storeId,
      filters: _filters,
      page: currentPage - 1,
    );
  }

  ValidationFailure? _validateFiltersAgainstCurrentParameters(
    Map<String, Object?> filters,
  ) {
    final parameters = _detail?.parameters;
    if (parameters == null || parameters.isEmpty) {
      return null;
    }

    final allowedKeys = parameters.map((parameter) => parameter.name).toSet();
    final blockedKeys = filters.keys
        .where((key) => !allowedKeys.contains(key))
        .toList(growable: false);
    if (blockedKeys.isNotEmpty) {
      return ValidationFailure(
        message: 'Report detail filter keys are outside user grant',
        userMessage: 'Alguns filtros nao estao liberados para este usuario.',
        context: <String, Object?>{
          'blockedFilterKeys': blockedKeys.join(','),
        },
      );
    }

    final storeParameter = parameters
        .where((parameter) => parameter.name == 'store')
        .firstOrNull;
    if (storeParameter == null) {
      return null;
    }

    final storeFilter = filters['store'];
    if (storeFilter is! String) {
      return null;
    }

    final isStoreAllowed = storeParameter.options.any(
      (option) => option.value == storeFilter,
    );
    if (isStoreAllowed) {
      return null;
    }

    return const ValidationFailure(
      message: 'Report detail store filter is outside user scope',
      userMessage: 'A loja selecionada nao esta liberada para este usuario.',
      context: <String, Object?>{
        'field': 'store',
      },
    );
  }
}
