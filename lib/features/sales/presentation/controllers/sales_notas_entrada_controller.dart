import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/agent_query_failure_classification.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_repository.dart';
import 'package:colmeia/features/sales/application/load_notas_entrada_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_search.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

/// Presentation state for the numbered entrada-notes report.
class SalesNotasEntradaController extends ChangeNotifier {
  SalesNotasEntradaController({
    required this._sessionService,
    required LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase,
    required ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientToken,
    required this._notasEntradaRepository,
    this._loadRowsForShare,
    this._relayCancelScopeBinder,
    DateTime? referenceDate,
  }) : _loadAgentsUseCase = loadSalesAvailableAgentsUseCase,
       _resolveClientToken = resolveSalesAgentClientToken {
    final defaults = _defaultRange(referenceDate ?? DateTime.now());
    final restored = _restoreState(
      _sessionService.restoreCardFilters(cardId),
      fallbackRange: defaults,
    );
    _dataLancamentoInicio = restored.range.start;
    _dataLancamentoFim = restored.range.end;
    _pageSize = restored.pageSize;
    _searchTerm = restored.searchTerm;
    _selectedAgentId = _sessionService.selectedAgentId;
  }

  static const String cardId = 'notas_entrada';
  static const String _dataLancamentoInicioKey = 'data_lancamento_inicio_ms';
  static const String _dataLancamentoFimKey = 'data_lancamento_fim_ms';
  static const String _pageSizeKey = 'pageSize';

  final SalesSessionService _sessionService;
  final LoadAvailableAgentsForSales _loadAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase _resolveClientToken;
  final NotasEntradaRepository _notasEntradaRepository;
  final LoadNotasEntradaRowsForShareUseCase? _loadRowsForShare;
  final AgentQueriesRelayCancelScopeBinder? _relayCancelScopeBinder;

  String? _boundUserId;
  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = const <DashboardAgentOption>[];
  DateTime _dataLancamentoInicio = DateTime(2000);
  DateTime _dataLancamentoFim = DateTime(2000);
  List<NotaEntradaRow> _rows = const <NotaEntradaRow>[];
  int _page = 1;
  int _pageSize = NotasEntradaFilter.defaultPageSize;
  int _totalCount = 0;
  String? _searchTerm;
  AppFailure? _loadFailure;
  bool _isLoading = false;
  bool _missingClientToken = false;
  int _loadGeneration = 0;
  AgentQueriesCancelScope? _cancelScope;
  AgentQueriesCancelScope? _shareCancelScope;
  bool _disposed = false;

  String? get selectedAgentId => _selectedAgentId;
  List<DashboardAgentOption> get availableAgents => _availableAgents;
  DateTime get dataLancamentoInicio => _dataLancamentoInicio;
  DateTime get dataLancamentoFim => _dataLancamentoFim;
  List<NotaEntradaRow> get rows => _rows;
  AppFailure? get loadFailure => _loadFailure;
  bool get isLoading => _isLoading;
  bool get missingClientToken => _missingClientToken;
  int get page => _page;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  String? get searchTerm => _searchTerm;
  int get totalPages => _totalCount <= 0 ? 0 : (_totalCount / _pageSize).ceil();
  int get rangeStart => _rows.isEmpty ? 0 : ((_page - 1) * _pageSize) + 1;
  int get rangeEnd => _rows.isEmpty ? 0 : rangeStart + _rows.length - 1;
  bool get hasPreviousPage => _page > 1;
  bool get hasNextPage => totalPages > 0 && _page < totalPages;
  bool get canShare => !_isLoading && _totalCount > 0;
  bool get canOpenFullscreen => !_isLoading && _rows.isNotEmpty;

  /// True only for the first page of a new query, so paging can keep
  /// the visible rows instead of replacing them with a skeleton.
  bool get showsLoadingSkeleton =>
      _isLoading && _rows.isEmpty && _loadFailure == null;

  DashboardAgentOption? get selectedAgent {
    final selectedId = _selectedAgentId;
    if (selectedId == null) {
      return null;
    }
    for (final agent in _availableAgents) {
      if (agent.agentId == selectedId) {
        return agent;
      }
    }
    return null;
  }

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) {
      return;
    }

    _boundUserId = userId;
    _loadGeneration += 1;
    _cancelScope?.cancelAll();
    _shareCancelScope?.cancelAll();
    _availableAgents = const <DashboardAgentOption>[];
    _rows = const <NotaEntradaRow>[];
    _page = 1;
    _totalCount = 0;
    _loadFailure = null;
    _missingClientToken = false;
    _isLoading = userId != null;
    _notifyListenersIfAlive();

    if (userId == null) {
      return;
    }

    try {
      final agents = await _loadAgentsUseCase(userId);
      if (_isStale(userId)) {
        return;
      }
      _availableAgents = List<DashboardAgentOption>.unmodifiable(agents);
      _selectedAgentId = reconcileSelectedSalesAgentId(
        agents: _availableAgents,
        previousSelectedId: _selectedAgentId,
      );
      _missingClientToken = selectedAgent?.missingLocalClientToken ?? false;
      _isLoading = false;
      _notifyListenersIfAlive();

      if (_selectedAgentId != null && !_missingClientToken) {
        await _loadPage(clearVisibleRows: true);
      }
    } on Object catch (error, stackTrace) {
      if (_isStale(userId)) {
        return;
      }
      _isLoading = false;
      _loadFailure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Could not load available sales agents.',
      );
      _notifyListenersIfAlive();
    }
  }

  Future<void> applyFilters({
    required String? selectedAgentId,
    required DateTime dataLancamentoInicio,
    required DateTime dataLancamentoFim,
  }) async {
    final normalizedStart = _calendarDate(dataLancamentoInicio);
    final normalizedEnd = _calendarDate(dataLancamentoFim);
    final orderedStart = normalizedEnd.isBefore(normalizedStart)
        ? normalizedEnd
        : normalizedStart;
    final orderedEnd = normalizedEnd.isBefore(normalizedStart)
        ? normalizedStart
        : normalizedEnd;
    final normalizedAgentId = selectedAgentId?.trim();

    _selectedAgentId = normalizedAgentId == null || normalizedAgentId.isEmpty
        ? null
        : normalizedAgentId;
    _dataLancamentoInicio = orderedStart;
    _dataLancamentoFim = orderedEnd;
    _page = 1;
    _loadFailure = null;
    _missingClientToken = selectedAgent?.missingLocalClientToken ?? false;
    unawaited(_sessionService.setSelectedAgentId(_selectedAgentId));
    unawaited(_persistFilters());
    _shareCancelScope?.cancelAll();

    if (_selectedAgentId == null || _missingClientToken) {
      _rows = const <NotaEntradaRow>[];
      _totalCount = 0;
      _isLoading = false;
      _notifyListenersIfAlive();
      return;
    }

    await _loadPage(clearVisibleRows: true);
  }

  Future<void> reload() => _loadPage(clearVisibleRows: _rows.isEmpty);

  Future<void> applySearch(String? raw) async {
    final next = SalesNotasEntradaSearch.normalize(raw);
    if (next == _searchTerm) {
      return;
    }
    _searchTerm = next;
    _page = 1;
    _shareCancelScope?.cancelAll();
    unawaited(_persistFilters());
    await _loadPage(clearVisibleRows: true);
  }

  Future<void> showPage(int page) async {
    final nextPage = NotasEntradaFilter.sanitizePage(page);
    if (nextPage == _page || _isLoading) {
      return;
    }
    if (totalPages > 0 && nextPage > totalPages) {
      return;
    }
    _page = nextPage;
    await _loadPage(clearVisibleRows: false);
  }

  Future<void> setPageSize(int pageSize) async {
    final nextSize = NotasEntradaFilter.sanitizePageSize(pageSize);
    if (nextSize == _pageSize) {
      return;
    }
    _pageSize = nextSize;
    _page = 1;
    _shareCancelScope?.cancelAll();
    unawaited(_persistFilters());
    await _loadPage(clearVisibleRows: true);
  }

  Future<void> _loadPage({required bool clearVisibleRows}) async {
    final userId = _boundUserId;
    final agentId = _selectedAgentId;
    if (userId == null || agentId == null) {
      return;
    }
    if (selectedAgent?.missingLocalClientToken ?? false) {
      _missingClientToken = true;
      _isLoading = false;
      _notifyListenersIfAlive();
      return;
    }

    final generation = ++_loadGeneration;
    final scope = _replaceCancelScope();
    _isLoading = true;
    _loadFailure = null;
    _missingClientToken = false;
    if (clearVisibleRows) {
      _rows = const <NotaEntradaRow>[];
      _totalCount = 0;
    }
    _notifyListenersIfAlive();

    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (_isStale(userId, generation: generation)) {
      return;
    }
    if (clientToken == null) {
      _isLoading = false;
      _missingClientToken = true;
      _notifyListenersIfAlive();
      return;
    }

    final result = await _notasEntradaRepository.loadPage(
      userId: userId,
      agentId: agentId,
      clientToken: clientToken,
      filter: NotasEntradaFilter(
        dataLancamentoInicio: _dataLancamentoInicio,
        dataLancamentoFim: _dataLancamentoFim,
        searchTerm: _searchTerm,
        page: _page,
        pageSize: _pageSize,
      ),
      cancelScope: scope,
    );
    if (_isStale(userId, generation: generation)) {
      return;
    }

    var reloadClampedPage = false;
    result.fold(
      (page) {
        _rows = List<NotaEntradaRow>.unmodifiable(page.items);
        final reportedTotal = page.totalCount < 0 ? 0 : page.totalCount;
        _totalCount = reportedTotal < _rows.length
            ? _rows.length
            : reportedTotal;
        _loadFailure = null;
        final maxPage = totalPages;
        if (maxPage > 0 && _page > maxPage) {
          _page = maxPage;
          reloadClampedPage = true;
        }
      },
      (failure) {
        if (!shouldSuppressAgentQueryFailureUi(failure)) {
          _loadFailure = failure;
        }
      },
    );
    _isLoading = false;
    _notifyListenersIfAlive();
    if (reloadClampedPage) {
      await _loadPage(clearVisibleRows: false);
    }
  }

  Future<AppResult<List<NotaEntradaRow>>> loadRowsForShare() async {
    final useCase = _loadRowsForShare;
    final userId = _boundUserId;
    final agentId = _selectedAgentId;
    if (useCase == null) {
      return const Failure(
        ValidationFailure(message: 'share_export_unavailable'),
      );
    }
    if (userId == null || agentId == null) {
      return const Failure(
        ValidationFailure(message: 'share_export_unavailable'),
      );
    }

    final shareScope = _replaceShareCancelScope();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (_disposed || shareScope.isCancelled) {
      return const Failure(OperationCancelledFailure());
    }
    if (clientToken == null) {
      return const Failure(
        SessionFailure(
          message: 'Missing client token for notas entrada share',
        ),
      );
    }

    return useCase(
      userId: userId,
      agentId: agentId,
      clientToken: clientToken,
      filter: NotasEntradaFilter(
        dataLancamentoInicio: _dataLancamentoInicio,
        dataLancamentoFim: _dataLancamentoFim,
        searchTerm: _searchTerm,
      ),
      totalCount: _totalCount,
      cancelScope: shareScope,
    );
  }

  AgentQueriesCancelScope _replaceCancelScope() {
    _cancelScope?.cancelAll();
    final next = AgentQueriesCancelScope();
    _relayCancelScopeBinder?.call(next);
    _cancelScope = next;
    return next;
  }

  AgentQueriesCancelScope _replaceShareCancelScope() {
    _shareCancelScope?.cancelAll();
    final next = AgentQueriesCancelScope();
    _relayCancelScopeBinder?.call(next);
    _shareCancelScope = next;
    return next;
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(cardId, <String, Object?>{
      _dataLancamentoInicioKey: _dataLancamentoInicio.millisecondsSinceEpoch,
      _dataLancamentoFimKey: _dataLancamentoFim.millisecondsSinceEpoch,
      _pageSizeKey: _pageSize,
      SalesNotasEntradaSearch.persistSearchTermKey: _searchTerm,
    });
  }

  bool _isStale(String userId, {int? generation}) {
    return _disposed ||
        _boundUserId != userId ||
        (generation != null && _loadGeneration != generation);
  }

  void _notifyListenersIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelScope?.cancelAll();
    _shareCancelScope?.cancelAll();
    super.dispose();
  }

  static _NotasEntradaDateRange _defaultRange(DateTime reference) {
    final end = _calendarDate(reference);
    return _NotasEntradaDateRange(
      start: DateTime(end.year, end.month),
      end: end,
    );
  }

  static _RestoredNotasEntradaState _restoreState(
    Map<String, Object?> persisted, {
    required _NotasEntradaDateRange fallbackRange,
  }) {
    return _RestoredNotasEntradaState(
      range: _restoreRange(persisted, fallback: fallbackRange),
      pageSize: _restorePageSize(persisted[_pageSizeKey]),
      searchTerm: SalesNotasEntradaSearch.normalize(
        persisted[SalesNotasEntradaSearch.persistSearchTermKey],
      ),
    );
  }

  static _NotasEntradaDateRange _restoreRange(
    Map<String, Object?> persisted, {
    required _NotasEntradaDateRange fallback,
  }) {
    final startMillis = persisted[_dataLancamentoInicioKey];
    final endMillis = persisted[_dataLancamentoFimKey];
    if (startMillis is! int || endMillis is! int) {
      return fallback;
    }
    final start = _calendarDate(
      DateTime.fromMillisecondsSinceEpoch(startMillis),
    );
    final end = _calendarDate(DateTime.fromMillisecondsSinceEpoch(endMillis));
    if (end.isBefore(start)) {
      return fallback;
    }
    return _NotasEntradaDateRange(start: start, end: end);
  }

  static int _restorePageSize(Object? raw) {
    if (raw is int) {
      return NotasEntradaFilter.sanitizePageSize(raw);
    }
    if (raw is num) {
      return NotasEntradaFilter.sanitizePageSize(raw.round());
    }
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null) {
        return NotasEntradaFilter.sanitizePageSize(parsed);
      }
    }
    return NotasEntradaFilter.defaultPageSize;
  }

  static DateTime _calendarDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _NotasEntradaDateRange {
  const _NotasEntradaDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _RestoredNotasEntradaState {
  const _RestoredNotasEntradaState({
    required this.range,
    required this.pageSize,
    this.searchTerm,
  });

  final _NotasEntradaDateRange range;
  final int pageSize;
  final String? searchTerm;
}
