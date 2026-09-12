import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/agent_query_failure_classification.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_resumo_fornecedor_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_resumo_fornecedor_repository.dart';
import 'package:colmeia/features/sales/application/load_notas_entrada_resumo_fornecedor_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/load_notas_entrada_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/sales_notas_entrada_view.dart';
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
    required this._resumoFornecedorRepository,
    this._loadRowsForShare,
    this._loadSummaryRowsForShare,
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
    _view = restored.view;
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
  final NotasEntradaResumoFornecedorRepository _resumoFornecedorRepository;
  final LoadNotasEntradaRowsForShareUseCase? _loadRowsForShare;
  final LoadNotasEntradaResumoFornecedorRowsForShareUseCase?
  _loadSummaryRowsForShare;
  final AgentQueriesRelayCancelScopeBinder? _relayCancelScopeBinder;

  String? _boundUserId;
  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = const <DashboardAgentOption>[];
  DateTime _dataLancamentoInicio = DateTime(2000);
  DateTime _dataLancamentoFim = DateTime(2000);
  List<NotaEntradaRow> _rows = const <NotaEntradaRow>[];
  List<NotaEntradaResumoFornecedorRow> _summaryRows =
      const <NotaEntradaResumoFornecedorRow>[];
  int _notesPage = 1;
  int _summaryPage = 1;
  int _pageSize = NotasEntradaFilter.defaultPageSize;
  int _notesTotalCount = 0;
  int _summaryTotalCount = 0;
  double _notesTotalValorCompra = 0;
  double _summaryTotalValorCompra = 0;
  int? _notesLoadedFingerprint;
  int? _summaryLoadedFingerprint;
  SalesNotasEntradaView _view = SalesNotasEntradaView.notes;
  String? _searchTerm;
  int? _codFornecedor;
  String? _supplierScopeName;
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
  SalesNotasEntradaView get view => _view;
  List<NotaEntradaRow> get rows => _rows;
  List<NotaEntradaResumoFornecedorRow> get summaryRows => _summaryRows;
  AppFailure? get loadFailure => _loadFailure;
  bool get isLoading => _isLoading;
  bool get missingClientToken => _missingClientToken;
  int get page => switch (_view) {
    SalesNotasEntradaView.notes => _notesPage,
    SalesNotasEntradaView.bySupplier => _summaryPage,
  };
  int get pageSize => _pageSize;
  int get totalCount => switch (_view) {
    SalesNotasEntradaView.notes => _notesTotalCount,
    SalesNotasEntradaView.bySupplier => _summaryTotalCount,
  };
  double get totalValorCompra => switch (_view) {
    SalesNotasEntradaView.notes => _notesTotalValorCompra,
    SalesNotasEntradaView.bySupplier => _summaryTotalValorCompra,
  };
  String? get searchTerm => _searchTerm;
  String? get supplierScopeName {
    if (_codFornecedor == null) {
      return null;
    }
    final name = _supplierScopeName?.trim();
    if (name == null || name.isEmpty) {
      return '$_codFornecedor';
    }
    return name;
  }

  int get totalPages => _totalPagesFor(totalCount);
  int get rangeStart {
    final visibleCount = switch (_view) {
      SalesNotasEntradaView.notes => _rows.length,
      SalesNotasEntradaView.bySupplier => _summaryRows.length,
    };
    return visibleCount == 0 ? 0 : ((page - 1) * _pageSize) + 1;
  }

  int get rangeEnd {
    final visibleCount = switch (_view) {
      SalesNotasEntradaView.notes => _rows.length,
      SalesNotasEntradaView.bySupplier => _summaryRows.length,
    };
    return visibleCount == 0 ? 0 : rangeStart + visibleCount - 1;
  }

  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => totalPages > 0 && page < totalPages;
  bool get canShare => !_isLoading && totalCount > 0;
  bool get canOpenFullscreen =>
      !_isLoading &&
      switch (_view) {
        SalesNotasEntradaView.notes => _rows.isNotEmpty,
        SalesNotasEntradaView.bySupplier => _summaryRows.isNotEmpty,
      };

  /// True only for the first page of a new query, so paging can keep
  /// the visible rows instead of replacing them with a skeleton.
  bool get showsLoadingSkeleton =>
      _isLoading && _activeRowsAreEmpty && _loadFailure == null;

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
    _codFornecedor = null;
    _supplierScopeName = null;
    _invalidateBothViews(clearRows: true);
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
    _invalidateBothViews(clearRows: true);
    _loadFailure = null;
    _missingClientToken = selectedAgent?.missingLocalClientToken ?? false;
    unawaited(_sessionService.setSelectedAgentId(_selectedAgentId));
    unawaited(_persistFilters());
    _shareCancelScope?.cancelAll();

    if (_selectedAgentId == null || _missingClientToken) {
      _isLoading = false;
      _notifyListenersIfAlive();
      return;
    }

    await _loadPage(clearVisibleRows: true);
  }

  Future<void> reload() => _loadPage(clearVisibleRows: _activeRowsAreEmpty);

  Future<void> applySearch(String? raw) async {
    final next = SalesNotasEntradaSearch.normalize(raw);
    if (next == _searchTerm) {
      return;
    }
    _searchTerm = next;
    _codFornecedor = null;
    _supplierScopeName = null;
    _invalidateBothViews(clearRows: true);
    _shareCancelScope?.cancelAll();
    unawaited(_persistFilters());
    await _loadPage(clearVisibleRows: true);
  }

  Future<void> selectView(SalesNotasEntradaView next) async {
    if (next == _view) {
      return;
    }
    _view = next;
    _loadFailure = null;
    unawaited(_persistFilters());
    _shareCancelScope?.cancelAll();
    if (_isActiveViewFresh) {
      _notifyListenersIfAlive();
      return;
    }
    await _loadPage(clearVisibleRows: true);
  }

  Future<void> openSupplierNotes(NotaEntradaResumoFornecedorRow row) async {
    if (_isLoading || row.codFornecedor <= 0) {
      return;
    }
    _codFornecedor = row.codFornecedor;
    final name = row.nomeFornecedor.trim();
    _supplierScopeName = name.isEmpty ? '${row.codFornecedor}' : name;
    _view = SalesNotasEntradaView.notes;
    _invalidateBothViews(clearRows: true);
    _loadFailure = null;
    unawaited(_persistFilters());
    _shareCancelScope?.cancelAll();
    await _loadPage(clearVisibleRows: true);
  }

  Future<void> clearSupplierScope() async {
    if (_codFornecedor == null) {
      return;
    }
    _codFornecedor = null;
    _supplierScopeName = null;
    _invalidateBothViews(clearRows: true);
    _shareCancelScope?.cancelAll();
    await _loadPage(clearVisibleRows: true);
  }

  Future<void> showPage(int page) async {
    final nextPage = NotasEntradaFilter.sanitizePage(page);
    if (nextPage == this.page || _isLoading) {
      return;
    }
    if (totalPages > 0 && nextPage > totalPages) {
      return;
    }
    switch (_view) {
      case SalesNotasEntradaView.notes:
        _notesPage = nextPage;
      case SalesNotasEntradaView.bySupplier:
        _summaryPage = nextPage;
    }
    await _loadPage(clearVisibleRows: false);
  }

  Future<void> setPageSize(int pageSize) async {
    final nextSize = NotasEntradaFilter.sanitizePageSize(pageSize);
    if (nextSize == _pageSize) {
      return;
    }
    _pageSize = nextSize;
    _invalidateBothViews(clearRows: true);
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
    final loadingView = _view;
    _isLoading = true;
    _loadFailure = null;
    _missingClientToken = false;
    if (clearVisibleRows) {
      _clearActiveRows(loadingView);
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

    final filter = NotasEntradaFilter(
      dataLancamentoInicio: _dataLancamentoInicio,
      dataLancamentoFim: _dataLancamentoFim,
      searchTerm: _searchTerm,
      codFornecedor: _codFornecedor,
      page: switch (loadingView) {
        SalesNotasEntradaView.notes => _notesPage,
        SalesNotasEntradaView.bySupplier => _summaryPage,
      },
      pageSize: _pageSize,
    );

    var reloadClampedPage = false;
    switch (loadingView) {
      case SalesNotasEntradaView.notes:
        final result = await _notasEntradaRepository.loadPage(
          userId: userId,
          agentId: agentId,
          clientToken: clientToken,
          filter: filter,
          cancelScope: scope,
        );
        if (_isStale(userId, generation: generation)) {
          return;
        }
        reloadClampedPage = _applyNotesResult(result);
      case SalesNotasEntradaView.bySupplier:
        final result = await _resumoFornecedorRepository.loadPage(
          userId: userId,
          agentId: agentId,
          clientToken: clientToken,
          filter: filter,
          cancelScope: scope,
        );
        if (_isStale(userId, generation: generation)) {
          return;
        }
        reloadClampedPage = _applySummaryResult(result);
    }

    _isLoading = false;
    _notifyListenersIfAlive();
    if (reloadClampedPage) {
      await _loadPage(clearVisibleRows: false);
    }
  }

  bool _applyNotesResult(AppResult<NotasEntradaPageResult> result) {
    var reloadClampedPage = false;
    result.fold(
      (page) {
        _rows = List<NotaEntradaRow>.unmodifiable(page.items);
        _notesTotalCount = _sanitizedTotal(page.totalCount, _rows.length);
        _notesTotalValorCompra = _sanitizedAmount(page.totalValorCompra);
        _notesLoadedFingerprint = _scopeFingerprint;
        _loadFailure = null;
        final maxPage = _totalPagesFor(_notesTotalCount);
        if (maxPage > 0 && _notesPage > maxPage) {
          _notesPage = maxPage;
          reloadClampedPage = true;
        }
      },
      (failure) {
        if (!shouldSuppressAgentQueryFailureUi(failure)) {
          _loadFailure = failure;
        }
      },
    );
    return reloadClampedPage;
  }

  bool _applySummaryResult(
    AppResult<NotasEntradaResumoFornecedorPageResult> result,
  ) {
    var reloadClampedPage = false;
    result.fold(
      (page) {
        _summaryRows = List<NotaEntradaResumoFornecedorRow>.unmodifiable(
          page.items,
        );
        _summaryTotalCount = _sanitizedTotal(
          page.totalCount,
          _summaryRows.length,
        );
        _summaryTotalValorCompra = _sanitizedAmount(page.totalValorCompra);
        _summaryLoadedFingerprint = _scopeFingerprint;
        _loadFailure = null;
        final maxPage = _totalPagesFor(_summaryTotalCount);
        if (maxPage > 0 && _summaryPage > maxPage) {
          _summaryPage = maxPage;
          reloadClampedPage = true;
        }
      },
      (failure) {
        if (!shouldSuppressAgentQueryFailureUi(failure)) {
          _loadFailure = failure;
        }
      },
    );
    return reloadClampedPage;
  }

  Future<AppResult<List<NotaEntradaRow>>> loadRowsForShare() async {
    final useCase = _loadRowsForShare;
    final prepared = await _prepareShare(
      useCaseAvailable: useCase != null,
    );
    AppFailure? failure;
    _ShareLoadContext? context;
    prepared.fold(
      (value) => context = value,
      (err) => failure = err,
    );
    if (failure != null) {
      return Failure(failure!);
    }
    return useCase!(
      userId: context!.userId,
      agentId: context!.agentId,
      clientToken: context!.clientToken,
      filter: context!.filter,
      totalCount: _notesTotalCount,
      cancelScope: context!.cancelScope,
    );
  }

  Future<AppResult<List<NotaEntradaResumoFornecedorRow>>>
  loadSummaryRowsForShare() async {
    final useCase = _loadSummaryRowsForShare;
    final prepared = await _prepareShare(
      useCaseAvailable: useCase != null,
    );
    AppFailure? failure;
    _ShareLoadContext? context;
    prepared.fold(
      (value) => context = value,
      (err) => failure = err,
    );
    if (failure != null) {
      return Failure(failure!);
    }
    return useCase!(
      userId: context!.userId,
      agentId: context!.agentId,
      clientToken: context!.clientToken,
      filter: context!.filter,
      totalCount: _summaryTotalCount,
      cancelScope: context!.cancelScope,
    );
  }

  Future<AppResult<_ShareLoadContext>> _prepareShare({
    required bool useCaseAvailable,
  }) async {
    final userId = _boundUserId;
    final agentId = _selectedAgentId;
    if (!useCaseAvailable || userId == null || agentId == null) {
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

    return Success(
      _ShareLoadContext(
        userId: userId,
        agentId: agentId,
        clientToken: clientToken,
        cancelScope: shareScope,
        filter: NotasEntradaFilter(
          dataLancamentoInicio: _dataLancamentoInicio,
          dataLancamentoFim: _dataLancamentoFim,
          searchTerm: _searchTerm,
          codFornecedor: _codFornecedor,
        ),
      ),
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
      SalesNotasEntradaView.persistKey: _view.name,
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

  int get _scopeFingerprint => Object.hash(
    _selectedAgentId,
    _dataLancamentoInicio,
    _dataLancamentoFim,
    _searchTerm,
    _codFornecedor,
    _pageSize,
  );

  bool get _isActiveViewFresh => switch (_view) {
    SalesNotasEntradaView.notes => _notesLoadedFingerprint == _scopeFingerprint,
    SalesNotasEntradaView.bySupplier =>
      _summaryLoadedFingerprint == _scopeFingerprint,
  };

  bool get _activeRowsAreEmpty => switch (_view) {
    SalesNotasEntradaView.notes => _rows.isEmpty,
    SalesNotasEntradaView.bySupplier => _summaryRows.isEmpty,
  };

  void _invalidateBothViews({required bool clearRows}) {
    _notesPage = 1;
    _summaryPage = 1;
    _notesLoadedFingerprint = null;
    _summaryLoadedFingerprint = null;
    if (clearRows) {
      _rows = const <NotaEntradaRow>[];
      _summaryRows = const <NotaEntradaResumoFornecedorRow>[];
      _notesTotalCount = 0;
      _summaryTotalCount = 0;
      _notesTotalValorCompra = 0;
      _summaryTotalValorCompra = 0;
    }
  }

  void _clearActiveRows(SalesNotasEntradaView view) {
    switch (view) {
      case SalesNotasEntradaView.notes:
        _rows = const <NotaEntradaRow>[];
        _notesTotalCount = 0;
        _notesTotalValorCompra = 0;
      case SalesNotasEntradaView.bySupplier:
        _summaryRows = const <NotaEntradaResumoFornecedorRow>[];
        _summaryTotalCount = 0;
        _summaryTotalValorCompra = 0;
    }
  }

  static int _sanitizedTotal(int reportedTotal, int rowCount) {
    final total = reportedTotal < 0 ? 0 : reportedTotal;
    return total < rowCount ? rowCount : total;
  }

  static double _sanitizedAmount(double reportedTotal) {
    if (reportedTotal.isNaN || reportedTotal < 0) {
      return 0;
    }
    return reportedTotal;
  }

  int _totalPagesFor(int count) => count <= 0 ? 0 : (count / _pageSize).ceil();

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
      view: SalesNotasEntradaView.fromPersisted(
        persisted[SalesNotasEntradaView.persistKey],
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
    required this.view,
    this.searchTerm,
  });

  final _NotasEntradaDateRange range;
  final int pageSize;
  final SalesNotasEntradaView view;
  final String? searchTerm;
}

class _ShareLoadContext {
  const _ShareLoadContext({
    required this.userId,
    required this.agentId,
    required this.clientToken,
    required this.cancelScope,
    required this.filter,
  });

  final String userId;
  final String agentId;
  final String clientToken;
  final AgentQueriesCancelScope cancelScope;
  final NotasEntradaFilter filter;
}
