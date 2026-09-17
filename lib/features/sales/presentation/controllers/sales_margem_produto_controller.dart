import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_margem_produto_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/sales/application/load_margem_produto_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

enum SalesMargemProdutoLoadKind {
  success,
  failure,
  skipped,
  superseded,
}

@immutable
class SalesMargemProdutoLoadOutcome {
  const SalesMargemProdutoLoadOutcome._(this.kind, {this.loadFailure});

  const SalesMargemProdutoLoadOutcome.success()
    : this._(SalesMargemProdutoLoadKind.success);

  const SalesMargemProdutoLoadOutcome.failure(AppFailure failure)
    : this._(SalesMargemProdutoLoadKind.failure, loadFailure: failure);

  const SalesMargemProdutoLoadOutcome.skipped()
    : this._(SalesMargemProdutoLoadKind.skipped);

  const SalesMargemProdutoLoadOutcome.superseded()
    : this._(SalesMargemProdutoLoadKind.superseded);

  final SalesMargemProdutoLoadKind kind;
  final AppFailure? loadFailure;

  bool get isSuccess => kind == SalesMargemProdutoLoadKind.success;
  bool get isFailure => kind == SalesMargemProdutoLoadKind.failure;
  bool get isSkipped => kind == SalesMargemProdutoLoadKind.skipped;
  bool get isSuperseded => kind == SalesMargemProdutoLoadKind.superseded;
}

/// Presentation state for the product-margin catalog page.
class SalesMargemProdutoController extends ChangeNotifier {
  SalesMargemProdutoController({
    required this._sessionService,
    required LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase,
    required ResolveSalesAgentClientTokenUseCase
    resolveSalesAgentClientTokenUseCase,
    required LoadMargemProdutoPageUseCase loadMargemProdutoPageUseCase,
    required LoadMargemProdutoRowsForShareUseCase loadRowsForShareUseCase,
    this._relayCancelScopeBinder,
  }) : _loadAgentsUseCase = loadSalesAvailableAgentsUseCase,
       _resolveClientTokenUseCase = resolveSalesAgentClientTokenUseCase,
       _loadMargemProduto = loadMargemProdutoPageUseCase,
       _loadRowsForShare = loadRowsForShareUseCase {
    _selectedAgentId = _sessionService.selectedAgentId;
    final restored = SalesMargemProdutoSort.restore(
      _sessionService.restoreCardFilters(SalesMargemProdutoSort.cardId),
    );
    _pageSize = restored.pageSize;
    _query = SalesMargemProdutoSort.queryFor(
      page: 1,
      pageSize: _pageSize,
      searchTerm: restored.searchTerm,
      sorts: SalesMargemProdutoSort.descriptorsFor(
        sortBy: restored.sortBy,
        sortDirection: restored.sortDirection,
      ),
    );
  }

  final SalesSessionService _sessionService;
  final LoadAvailableAgentsForSales _loadAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  final LoadMargemProdutoPageUseCase _loadMargemProduto;
  final LoadMargemProdutoRowsForShareUseCase _loadRowsForShare;
  final AgentQueriesRelayCancelScopeBinder? _relayCancelScopeBinder;

  String? _boundUserId;
  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = const <DashboardAgentOption>[];
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  int _page = 1;
  int _pageSize = SalesMargemProdutoSort.defaultPageSize;
  AppReportQuery _query = SalesMargemProdutoSort.queryFor(
    page: 1,
    pageSize: SalesMargemProdutoSort.defaultPageSize,
  );

  List<MargemProdutoRow> _rows = const <MargemProdutoRow>[];
  int _totalCount = 0;
  bool _catalogLoading = false;
  AppFailure? _loadFailure;
  int _sqlLoadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;
  AgentQueriesCancelScope? _shareCancelScope;
  bool _disposed = false;

  String? get selectedAgentId => _selectedAgentId;
  List<DashboardAgentOption> get availableAgents => _availableAgents;
  List<MargemProdutoRow> get rows => _rows;
  int get totalCount => _totalCount;
  int get page => _page;
  int get pageSize => _pageSize;
  AppReportQuery get query => _query;
  bool get isLoading => _catalogLoading;
  AppFailure? get loadFailure => _loadFailure;
  bool get canOpenFullscreen => !_catalogLoading && _rows.isNotEmpty;
  bool get canShare => !_catalogLoading && _totalCount > 0;

  AppReportPageInfo get pageInfo => SalesMargemProdutoSort.pageInfo(
    page: _page,
    pageSize: _pageSize,
    totalCount: _totalCount,
  );

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

  String selectedAgentName(String emptyLabel) =>
      selectedAgent?.name ?? emptyLabel;

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) {
      return;
    }

    _boundUserId = userId;
    _sqlLoadGeneration += 1;
    _sqlCancelScope?.cancelAll();
    _shareCancelScope?.cancelAll();
    _availableAgents = const <DashboardAgentOption>[];
    _rows = const <MargemProdutoRow>[];
    _totalCount = 0;
    _loadFailure = null;
    _catalogLoading = userId != null;
    _notify();

    if (userId == null) {
      return;
    }

    final agents = await _loadAgentsUseCase(userId);
    if (_disposed || _boundUserId != userId) {
      return;
    }

    final nextSelection = reconcileSelectedSalesAgentId(
      agents: agents,
      previousSelectedId: _selectedAgentId,
    );
    _availableAgents = List<DashboardAgentOption>.unmodifiable(agents);
    _selectedAgentId = nextSelection;
    _catalogLoading = nextSelection != null;
    _notify();

    if (nextSelection != _sessionService.selectedAgentId) {
      unawaited(_sessionService.setSelectedAgentId(nextSelection));
    }
  }

  Future<SalesMargemProdutoLoadOutcome> loadCatalog({
    bool clearVisibleCatalog = false,
  }) async {
    final generation = ++_sqlLoadGeneration;
    _sqlCancelScope = _replaceCancelScope(_sqlCancelScope);
    final sqlScope = _sqlCancelScope!;

    final userId = _boundUserId;
    final agentId = _selectedAgentId?.trim();

    _catalogLoading = true;
    _loadFailure = null;
    if (clearVisibleCatalog) {
      _rows = const <MargemProdutoRow>[];
      _totalCount = 0;
    }
    _notify();

    if (userId == null || agentId == null || agentId.isEmpty) {
      if (_disposed || generation != _sqlLoadGeneration) {
        return const SalesMargemProdutoLoadOutcome.superseded();
      }
      _catalogLoading = false;
      _rows = const <MargemProdutoRow>[];
      _totalCount = 0;
      _notify();
      return const SalesMargemProdutoLoadOutcome.skipped();
    }

    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (_disposed || generation != _sqlLoadGeneration) {
      return const SalesMargemProdutoLoadOutcome.superseded();
    }
    if (clientToken == null) {
      final failure = SessionFailure(
        message: 'Missing client token for margem produto lookup',
        context: <String, Object?>{
          'operation': 'loadMargemProdutoPage',
          'agentId': agentId,
        },
      );
      _catalogLoading = false;
      _rows = const <MargemProdutoRow>[];
      _totalCount = 0;
      _loadFailure = failure;
      _notify();
      return SalesMargemProdutoLoadOutcome.failure(failure);
    }

    final result = await _loadMargemProduto(
      userId: userId,
      agentId: agentId,
      filter: _catalogFilter(page: _page, pageSize: _pageSize),
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (_disposed || generation != _sqlLoadGeneration) {
      return const SalesMargemProdutoLoadOutcome.superseded();
    }

    AppFailure? failure;
    var pageResult = const MargemProdutoPageResult(
      items: <MargemProdutoRow>[],
      totalCount: 0,
    );
    result.fold(
      (value) => pageResult = value,
      (err) => failure = err,
    );
    if (failure != null) {
      _catalogLoading = false;
      _rows = const <MargemProdutoRow>[];
      _totalCount = 0;
      _loadFailure = failure;
      _notify();
      return SalesMargemProdutoLoadOutcome.failure(failure!);
    }

    final totalPages = pageResult.totalCount <= 0
        ? 0
        : (pageResult.totalCount / _pageSize).ceil();
    if (totalPages > 0 && _page > totalPages) {
      _page = totalPages;
      _query = SalesMargemProdutoSort.queryFor(
        page: _page,
        pageSize: _pageSize,
        previous: _query,
      );
      _notify();
      return loadCatalog();
    }

    _rows = pageResult.items;
    _totalCount = pageResult.totalCount;
    _catalogLoading = false;
    _loadFailure = null;
    _notify();
    return const SalesMargemProdutoLoadOutcome.success();
  }

  Future<SalesMargemProdutoLoadOutcome?> applyFilters(
    Map<String, Object?> next,
  ) async {
    final nextAgentId = (next['agentId'] as String?)?.trim();
    final normalizedAgentId = nextAgentId == null || nextAgentId.isEmpty
        ? null
        : nextAgentId;
    if (normalizedAgentId == _selectedAgentId) {
      return null;
    }
    _shareCancelScope?.cancelAll();
    _selectedAgentId = normalizedAgentId;
    _page = 1;
    _query = SalesMargemProdutoSort.queryFor(
      page: 1,
      pageSize: _pageSize,
      previous: _query,
    );
    _notify();
    unawaited(_sessionService.setSelectedAgentId(normalizedAgentId));
    unawaited(_persistFilters());
    return loadCatalog(clearVisibleCatalog: true);
  }

  Future<SalesMargemProdutoLoadOutcome?> applyQuery(AppReportQuery next) {
    final nextSearch = SalesMargemProdutoSort.normalizeSearchTerm(
      next.searchTerm,
    );
    final currentSearch = SalesMargemProdutoSort.normalizeSearchTerm(
      _query.searchTerm,
    );
    if (nextSearch != currentSearch) {
      return applySearch(nextSearch, previous: next);
    }
    if (!SalesMargemProdutoSort.sortsEqual(next.sorts, _query.sorts)) {
      return applySort(
        SalesMargemProdutoSort.sanitizeSorts(next.sorts),
        previous: next,
      );
    }
    final nextPage = SalesMargemProdutoSort.sanitizePage(next.page);
    final nextPageSize = SalesMargemProdutoSort.sanitizePageSize(next.pageSize);
    if (nextPage == _page && nextPageSize == _pageSize) {
      return Future<SalesMargemProdutoLoadOutcome?>.value();
    }
    return applyPaging(
      page: nextPage,
      pageSize: nextPageSize,
      previous: next,
    );
  }

  Future<SalesMargemProdutoLoadOutcome> applySearch(
    String? searchTerm, {
    AppReportQuery? previous,
  }) async {
    _shareCancelScope?.cancelAll();
    _page = 1;
    _query = SalesMargemProdutoSort.queryFor(
      page: 1,
      pageSize: _pageSize,
      searchTerm: searchTerm,
      clearSearchTerm: searchTerm == null,
      previous: previous ?? _query,
    );
    _notify();
    unawaited(_persistFilters());
    return loadCatalog(clearVisibleCatalog: true);
  }

  Future<SalesMargemProdutoLoadOutcome> applySort(
    List<AppReportSortDescriptor> sorts, {
    AppReportQuery? previous,
  }) async {
    _shareCancelScope?.cancelAll();
    _page = 1;
    _query = SalesMargemProdutoSort.queryFor(
      page: 1,
      pageSize: _pageSize,
      sorts: sorts,
      previous: previous ?? _query,
    );
    _notify();
    unawaited(_persistFilters());
    return loadCatalog(clearVisibleCatalog: true);
  }

  Future<SalesMargemProdutoLoadOutcome?> applyPaging({
    required int page,
    required int pageSize,
    AppReportQuery? previous,
  }) async {
    final sanitizedSize = SalesMargemProdutoSort.sanitizePageSize(pageSize);
    final pageSizeChanged = sanitizedSize != _pageSize;
    final sanitizedPage = pageSizeChanged
        ? 1
        : SalesMargemProdutoSort.sanitizePage(page);
    if (!pageSizeChanged && sanitizedPage == _page) {
      return Future<SalesMargemProdutoLoadOutcome?>.value();
    }

    _pageSize = sanitizedSize;
    _page = sanitizedPage;
    _query = SalesMargemProdutoSort.queryFor(
      page: sanitizedPage,
      pageSize: sanitizedSize,
      previous: previous ?? _query,
    );
    _notify();
    unawaited(_persistFilters());
    return loadCatalog();
  }

  Future<AppResult<List<MargemProdutoRow>>> loadRowsForShare() async {
    final userId = _boundUserId;
    final agentId = _selectedAgentId?.trim();
    if (userId == null || agentId == null || agentId.isEmpty) {
      return const Failure(
        SessionFailure(
          message: 'Missing session for margem produto share',
        ),
      );
    }

    _shareCancelScope = _replaceCancelScope(_shareCancelScope);
    final shareScope = _shareCancelScope!;
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
          message: 'Missing client token for margem produto share',
        ),
      );
    }

    return _loadRowsForShare(
      userId: userId,
      agentId: agentId,
      filter: MargemProdutoFilter(
        searchTerm: SalesMargemProdutoSort.normalizeSearchTerm(
          _query.searchTerm,
        ),
        sortBy: SalesMargemProdutoSort.sortByFromQuery(_query),
        sortDirection: SalesMargemProdutoSort.sortDirectionFromQuery(_query),
      ),
      totalCount: _totalCount,
      clientToken: clientToken,
      cancelScope: shareScope,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _sqlCancelScope?.cancelAll();
    _shareCancelScope?.cancelAll();
    super.dispose();
  }

  MargemProdutoFilter _catalogFilter({
    required int page,
    required int pageSize,
  }) {
    return MargemProdutoFilter(
      searchTerm: SalesMargemProdutoSort.normalizeSearchTerm(
        _query.searchTerm,
      ),
      page: page,
      pageSize: pageSize,
      sortBy: SalesMargemProdutoSort.sortByFromQuery(_query),
      sortDirection: SalesMargemProdutoSort.sortDirectionFromQuery(_query),
    );
  }

  Future<String?> _resolveClientToken({
    required String userId,
    required String agentId,
  }) async {
    if (_cachedClientTokenUserId == userId &&
        _cachedClientTokenAgentId == agentId) {
      return _cachedClientToken;
    }

    final resolved = await _resolveClientTokenUseCase(
      userId: userId,
      agentId: agentId,
    );
    if (resolved != null) {
      _cachedClientTokenUserId = userId;
      _cachedClientTokenAgentId = agentId;
      _cachedClientToken = resolved;
    }
    return resolved;
  }

  AgentQueriesCancelScope _replaceCancelScope(
    AgentQueriesCancelScope? previous,
  ) {
    previous?.cancelAll();
    final next = AgentQueriesCancelScope();
    _relayCancelScopeBinder?.call(next);
    return next;
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(
      SalesMargemProdutoSort.cardId,
      SalesMargemProdutoSort.persistMap(
        pageSize: _pageSize,
        sortBy: SalesMargemProdutoSort.sortByFromQuery(_query),
        sortDirection: SalesMargemProdutoSort.sortDirectionFromQuery(_query),
        searchTerm: _query.searchTerm,
      ),
    );
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
