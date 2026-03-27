import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/application/usecases/load_reports_overview_use_case.dart';
import 'package:colmeia/features/reports/domain/entities/report_definition.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

class ReportsController extends ChangeNotifier {
  ReportsController(this._loadReportsOverviewUseCase);

  final LoadReportsOverviewUseCase _loadReportsOverviewUseCase;

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

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, Object?> _lastAppliedFilters = const <String, Object?>{};
  List<ReportDefinition> _availableReports = const <ReportDefinition>[];
  List<ReportParameterDescriptor> _parameters =
      const <ReportParameterDescriptor>[];
  List<ReportResultRow> _allRows = const <ReportResultRow>[];
  List<ReportResultRow> _rows = const <ReportResultRow>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, Object?> get lastAppliedFilters => _lastAppliedFilters;
  bool get hasAppliedFilters => _lastAppliedFilters.isNotEmpty;
  List<ReportDefinition> get availableReports => _availableReports;
  List<ReportParameterDescriptor> get parameters => _parameters;
  List<ReportResultRow> get rows => _rows;

  Future<void> loadOverview({
    required String userId,
    required StoreId activeStoreId,
  }) async {
    AppLogger.debug(
      'Starting reports load in controller',
      context: <String, Object?>{
        'operation': 'loadReportsOverview',
        'userId': userId,
        'activeStoreId': activeStoreId.value,
      },
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _loadReportsOverviewUseCase(
      userId: userId,
      activeStoreId: activeStoreId,
    );
    result.fold(
      (overview) {
        _availableReports = overview.availableReports;
        _parameters = overview.parameters;
        _allRows = overview.rows;
        _rows = overview.rows;
        _lastAppliedFilters = const <String, Object?>{};
        AppLogger.info(
          'Reports loaded in controller',
          context: <String, Object?>{
            'operation': 'loadReportsOverview',
            'userId': userId,
            'activeStoreId': activeStoreId.value,
            'reports': overview.availableReports.length,
            'rows': overview.rows.length,
          },
        );
      },
      (failure) {
        _availableReports = const <ReportDefinition>[];
        _parameters = const <ReportParameterDescriptor>[];
        _allRows = const <ReportResultRow>[];
        _rows = const <ReportResultRow>[];
        _errorMessage = failure.displayMessage;
        AppLogger.warning(
          'Reports load failed in controller',
          context: <String, Object?>{
            'operation': 'loadReportsOverview',
            'userId': userId,
            'activeStoreId': activeStoreId.value,
          },
        );
      },
    );

    _isLoading = false;
    _notifyListenersIfAlive();
  }

  AppResult<Map<String, Object?>> applyFilters(Map<String, Object?> filters) {
    try {
      _assertAllowedFilterKeys(filters);
      final normalizedFilters = _normalizeFilters(filters);
      final filteredRows = _filterRows(
        rows: _allRows,
        normalizedFilters: normalizedFilters,
      );

      _lastAppliedFilters = normalizedFilters;
      _rows = filteredRows;
      _errorMessage = null;
      AppLogger.info(
        'Report filters applied in controller',
        context: <String, Object?>{
          'operation': 'applyReportFilters',
          'filterKeys': normalizedFilters.keys.join(','),
          'rows': filteredRows.length,
        },
      );
      _notifyListenersIfAlive();

      return Success<Map<String, Object?>, AppFailure>(normalizedFilters);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Report filters rejected in controller',
        context: <String, Object?>{
          'operation': 'applyReportFilters',
          'filterKeys': filters.keys.join(','),
        },
        error: error,
        stackTrace: stackTrace,
      );
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to apply report filters',
        fallbackUserMessage:
            'Nao foi possivel aplicar os filtros do relatorio.',
        context: <String, Object?>{
          'operation': 'applyReportFilters',
        },
      );
      _errorMessage = failure.displayMessage;
      _notifyListenersIfAlive();

      return Failure<Map<String, Object?>, AppFailure>(failure);
    }
  }

  void _assertAllowedFilterKeys(Map<String, Object?> filters) {
    final allowedKeys = _parameters.map((parameter) => parameter.name).toSet();
    final providedKeys = filters.keys.toSet();
    final blockedKeys = providedKeys.difference(allowedKeys);
    if (blockedKeys.isEmpty) {
      return;
    }

    throw ValidationFailure(
      message: 'Report filter keys are outside user grant',
      userMessage: 'Alguns filtros nao estao liberados para este usuario.',
      context: <String, Object?>{
        'blockedFilterKeys': blockedKeys.join(','),
      },
    );
  }

  Map<String, Object?> _normalizeFilters(Map<String, Object?> filters) {
    final normalized = <String, Object?>{
      ...filters,
    };

    if (_hasParameter('store')) {
      final storeValue = filters['store'];
      if (storeValue is! String || storeValue.trim().isEmpty) {
        throw const ValidationFailure(
          message: 'Report filters require a valid store',
          userMessage: 'Selecione uma loja para consultar o relatorio.',
          context: <String, Object?>{
            'field': 'store',
          },
        );
      }
      final isStoreAllowed = _parameters
          .where((parameter) => parameter.name == 'store')
          .firstOrNull
          ?.options
          .any((option) => option.value == storeValue);
      if (isStoreAllowed != true) {
        throw const ValidationFailure(
          message: 'Report filters include a store outside user scope',
          userMessage:
              'A loja selecionada nao esta liberada para este usuario.',
          context: <String, Object?>{
            'field': 'store',
          },
        );
      }
      normalized['store'] = StoreId(storeValue).value;
    }

    if (_hasParameter('referenceDate')) {
      final referenceDate = filters['referenceDate'];
      if (referenceDate is! DateTime) {
        throw const ValidationFailure(
          message: 'Report filters require a reference date',
          userMessage: 'Informe a data de referencia do relatorio.',
          context: <String, Object?>{
            'field': 'referenceDate',
          },
        );
      }
      normalized['referenceDate'] = referenceDate;
    }

    return normalized;
  }

  List<ReportResultRow> _filterRows({
    required List<ReportResultRow> rows,
    required Map<String, Object?> normalizedFilters,
  }) {
    if (!_hasParameter('store')) {
      return rows;
    }
    final storeFilter = normalizedFilters['store'];
    if (storeFilter is! String) {
      return rows;
    }

    final sellerQuery = (normalizedFilters['seller'] as String?)
        ?.trim()
        .toLowerCase();
    final selectedStoreLabel = _resolveStoreLabel(storeFilter);

    return rows
        .where((row) {
          final matchesStore = row.store == selectedStoreLabel;
          final matchesSeller =
              sellerQuery == null ||
              sellerQuery.isEmpty ||
              row.seller.toLowerCase().contains(sellerQuery);
          return matchesStore && matchesSeller;
        })
        .toList(growable: false);
  }

  String _resolveStoreLabel(String storeId) {
    final storeParameter = _parameters
        .where((parameter) => parameter.name == 'store')
        .firstOrNull;
    final storeOption = storeParameter?.options
        .where((option) => option.value == storeId)
        .firstOrNull;

    return storeOption?.label ?? storeId;
  }

  bool _hasParameter(String name) {
    return _parameters.any((parameter) => parameter.name == name);
  }
}
