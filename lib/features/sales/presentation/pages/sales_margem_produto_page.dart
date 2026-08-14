import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_chart_share_actions.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_margem_produto_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_error_panel_factory.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/load_margem_produto_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/share/sales_chart_share_export_filter.dart';
import 'package:colmeia/features/sales/presentation/share/sales_margem_produto_share.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_fullscreen.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_header_trailing.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:colmeia/shared/widgets/reports/app_report_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';

class SalesMargemProdutoPage extends StatefulWidget {
  const SalesMargemProdutoPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadCadastroFilialPageUseCase,
    required this.loadMargemProdutoPageUseCase,
    required this.loadRowsForShareUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final LoadCadastroFilialPageUseCase loadCadastroFilialPageUseCase;
  final LoadMargemProdutoPageUseCase loadMargemProdutoPageUseCase;
  final LoadMargemProdutoRowsForShareUseCase loadRowsForShareUseCase;
  final AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder;

  @override
  State<SalesMargemProdutoPage> createState() => _SalesMargemProdutoPageState();
}

class _SalesMargemProdutoPageState extends State<SalesMargemProdutoPage>
    with
        AutoRefreshStateMixin<SalesMargemProdutoPage>,
        SalesSingleAgentAutoRefreshMixin<SalesMargemProdutoPage>,
        SalesCardAutoRefreshBinding<SalesMargemProdutoPage>,
        AgentQueryRetryAfterHost<SalesMargemProdutoPage> {
  late final SalesSessionService _sessionService;
  late final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadCadastroFilialPageUseCase _loadCadastroFilial;
  late final LoadMargemProdutoPageUseCase _loadMargemProduto;
  late final LoadMargemProdutoRowsForShareUseCase _loadRowsForShare;
  final GlobalKey _shareKey = GlobalKey();
  final ValueNotifier<SalesMargemProdutoGridSnapshot> _gridView =
      ValueNotifier<SalesMargemProdutoGridSnapshot>(
        SalesMargemProdutoGridSnapshot.initial(),
      );

  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = <DashboardAgentOption>[];
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  List<CadastroFilialRow> _filiais = const <CadastroFilialRow>[];
  CadastroFilialRow? _selectedFilial;
  int? _preferredCodEmpresa;
  int? _preferredCodFilial;

  int _page = 1;
  int _pageSize = SalesMargemProdutoSort.defaultPageSize;
  AppReportQuery _query = SalesMargemProdutoSort.queryFor(
    page: 1,
    pageSize: SalesMargemProdutoSort.defaultPageSize,
  );

  List<MargemProdutoRow> _rows = const <MargemProdutoRow>[];
  int _totalCount = 0;

  bool _filiaisLoading = false;
  bool _catalogLoading = false;
  String? _error;
  AppFailure? _loadFailure;
  AppFailure? _filiaisFailure;

  int _filiaisGeneration = 0;
  int _sqlLoadGeneration = 0;
  AgentQueriesCancelScope? _filiaisCancelScope;
  AgentQueriesCancelScope? _sqlCancelScope;
  AgentQueriesCancelScope? _shareCancelScope;

  bool get _pageLoading => _filiaisLoading || _catalogLoading;

  bool get _canOpenFullscreen => !_pageLoading && _rows.isNotEmpty;

  bool get _canShare =>
      !_pageLoading && _totalCount > 0 && _selectedFilial != null;

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

  // Stable identity across builds; required for AppReportGrid column-cache hits.
  late List<AppReportColumn<MargemProdutoRow>> _columns;
  Locale? _columnsLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_columnsLocale == locale) {
      return;
    }
    _columnsLocale = locale;
    _columns = buildSalesMargemProdutoColumns(
      labels: SalesMargemProdutoColumnLabels.fromL10n(
        AppLocalizations.of(context),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService;
    _resolveClientTokenUseCase = widget.resolveSalesAgentClientTokenUseCase;
    _loadAgentsUseCase = widget.loadSalesAvailableAgentsUseCase;
    _loadCadastroFilial = widget.loadCadastroFilialPageUseCase;
    _loadMargemProduto = widget.loadMargemProdutoPageUseCase;
    _loadRowsForShare = widget.loadRowsForShareUseCase;
    _selectedAgentId = _sessionService.selectedAgentId;

    final restored = SalesMargemProdutoSort.restore(
      _sessionService.restoreCardFilters(SalesMargemProdutoSort.cardId),
    );
    _pageSize = restored.pageSize;
    _preferredCodEmpresa = restored.codEmpresa;
    _preferredCodFilial = restored.codFilial;
    _query = SalesMargemProdutoSort.queryFor(
      page: 1,
      pageSize: _pageSize,
      searchTerm: restored.searchTerm,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAgents());
    });
    _publishGridView();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _publishGridView();
  }

  void _publishGridView() {
    if (!mounted) {
      return;
    }
    _gridView.value = SalesMargemProdutoGridSnapshot(
      rows: _rows,
      pageInfo: SalesMargemProdutoSort.pageInfo(
        page: _page,
        pageSize: _pageSize,
        totalCount: _totalCount,
      ),
      query: _query,
      isLoading: _pageLoading && _loadFailure == null,
      loadFailure: _loadFailure,
    );
  }

  AgentQueriesCancelScope _replaceCancelScope(
    AgentQueriesCancelScope? previous,
  ) {
    previous?.cancelAll();
    final next = AgentQueriesCancelScope();
    widget.relayCancelScopeBinder?.call(next);
    return next;
  }

  @override
  void dispose() {
    _filiaisCancelScope?.cancelAll();
    _sqlCancelScope?.cancelAll();
    _shareCancelScope?.cancelAll();
    _gridView.dispose();
    super.dispose();
  }

  Future<void> _loadAgents() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    if (userId == null) {
      return;
    }

    final agents = await _loadAgentsUseCase(userId);
    if (!mounted) {
      return;
    }

    final authAfter = context.read<AuthController>();
    if (authAfter.session?.userId != userId) {
      return;
    }

    final nextSelection = reconcileSelectedSalesAgentId(
      agents: agents,
      previousSelectedId: _selectedAgentId,
    );
    setState(() {
      _availableAgents = agents;
      _selectedAgentId = nextSelection;
    });
    if (nextSelection != _sessionService.selectedAgentId) {
      unawaited(_sessionService.setSelectedAgentId(nextSelection));
    }
    unawaited(_loadFiliaisThenCatalog());
  }

  Future<void> _reload() => reloadWithAutoRefresh();

  @override
  SalesSessionService get salesSessionService => _sessionService;

  @override
  String get salesAutoRefreshCardId => SalesAutoRefreshCardIds.margemProduto;

  @override
  String? get autoRefreshSelectedAgentId => _selectedAgentId;

  @override
  List<DashboardAgentOption> get autoRefreshAvailableAgents => _availableAgents;

  @override
  bool get autoRefreshPageLoading => _pageLoading;

  @override
  Future<void> performAutoRefreshReload() async {
    if (_selectedFilial == null) {
      await _loadFiliaisThenCatalog();
      return;
    }
    await _loadCatalog();
  }

  Future<AppResult<List<CadastroFilialRow>>> _fetchFiliais(
    String agentId, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final l10n = AppLocalizations.of(context);
    if (userId == null) {
      return Failure<List<CadastroFilialRow>, AppFailure>(
        SessionFailure(
          message: 'Missing user session for cadastro filial lookup',
          userMessage: l10n.agentSqlErrorAuthenticationFailed,
          context: const <String, Object?>{
            'operation': 'loadCadastroFilialPage',
          },
        ),
      );
    }

    if (cancelScope != null) {
      widget.relayCancelScopeBinder?.call(cancelScope);
    }

    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (clientToken == null) {
      return Failure<List<CadastroFilialRow>, AppFailure>(
        SessionFailure(
          message: 'Missing client token for cadastro filial lookup',
          userMessage: l10n.agentSqlErrorAuthenticationFailed,
          context: <String, Object?>{
            'operation': 'loadCadastroFilialPage',
            'agentId': agentId,
          },
        ),
      );
    }

    final result = await _loadCadastroFilial(
      userId: userId,
      agentId: agentId,
      filter: const CadastroFilialFilter(
        pageSize: CadastroFilialFilter.maxPageSize,
        branchOptionsProjection: true,
      ),
      clientToken: clientToken,
      cancelScope: cancelScope,
    );
    final page = result.getOrNull();
    if (page != null) {
      return Success<List<CadastroFilialRow>, AppFailure>(page.items);
    }
    return Failure<List<CadastroFilialRow>, AppFailure>(
      result.exceptionOrNull()!,
    );
  }

  Future<void> _loadFiliaisThenCatalog() async {
    markAutoRefreshCancelled();
    final generation = ++_filiaisGeneration;
    final catalogGenerationAtStart = ++_sqlLoadGeneration;
    _filiaisCancelScope = _replaceCancelScope(_filiaisCancelScope);
    _sqlCancelScope?.cancelAll();
    _shareCancelScope?.cancelAll();
    final agentId = _selectedAgentId?.trim();
    if (agentId == null || agentId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _filiais = const <CadastroFilialRow>[];
        _selectedFilial = null;
        _filiaisLoading = false;
        _catalogLoading = false;
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
        _error = null;
        _loadFailure = null;
        _filiaisFailure = null;
      });
      return;
    }

    setState(() {
      _filiaisLoading = true;
      _catalogLoading = true;
      _filiaisFailure = null;
      _error = null;
      _loadFailure = null;
      _rows = const <MargemProdutoRow>[];
      _totalCount = 0;
    });

    final result = await _fetchFiliais(
      agentId,
      cancelScope: _filiaisCancelScope,
    );
    if (!mounted || generation != _filiaisGeneration) {
      return;
    }

    final items = result.getOrNull();
    if (items == null) {
      final failure = result.exceptionOrNull()!;
      setState(() {
        _filiais = const <CadastroFilialRow>[];
        _selectedFilial = null;
        _filiaisLoading = false;
        _catalogLoading = false;
        _filiaisFailure = failure;
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
      });
      onAgentQueryLoadFailure(failure);
      markAutoRefreshFailure();
      return;
    }

    final selected = salesMargemProdutoMatchFilial(
      items: items,
      codEmpresa: _preferredCodEmpresa,
      codFilial: _preferredCodFilial,
    );
    setState(() {
      _filiais = items;
      _selectedFilial = selected;
      _filiaisLoading = false;
      _filiaisFailure = null;
      _error = null;
      if (selected == null) {
        _catalogLoading = false;
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
      }
    });
    if (selected == null) {
      return;
    }
    if (_sqlLoadGeneration != catalogGenerationAtStart) {
      return;
    }
    await _loadCatalog();
  }

  Future<void> _loadCatalog({bool clearVisibleCatalog = false}) async {
    markAutoRefreshCancelled();
    final generation = ++_sqlLoadGeneration;
    _sqlCancelScope = _replaceCancelScope(_sqlCancelScope);
    final sqlScope = _sqlCancelScope!;

    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId?.trim();
    final filial = _selectedFilial;

    setState(() {
      _catalogLoading = true;
      _error = null;
      _loadFailure = null;
      if (clearVisibleCatalog) {
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
      }
    });

    if (userId == null ||
        agentId == null ||
        agentId.isEmpty ||
        filial == null) {
      if (!mounted || generation != _sqlLoadGeneration) {
        return;
      }
      setState(() {
        _catalogLoading = false;
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
      });
      return;
    }

    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (!mounted || generation != _sqlLoadGeneration) {
      return;
    }
    if (clientToken == null) {
      final failure = SessionFailure(
        message: 'Missing client token for margem produto lookup',
        userMessage: AppLocalizations.of(
          context,
        ).agentSqlErrorAuthenticationFailed,
        context: <String, Object?>{
          'operation': 'loadMargemProdutoPage',
          'agentId': agentId,
        },
      );
      setState(() {
        _catalogLoading = false;
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
        _loadFailure = failure;
        _error = null;
      });
      onAgentQueryLoadFailure(failure);
      markAutoRefreshCancelled();
      return;
    }

    final result = await _loadMargemProduto(
      userId: userId,
      agentId: agentId,
      filter: MargemProdutoFilter(
        codEmpresa: filial.codEmpresa,
        codFilial: filial.codFilial,
        searchTerm: SalesMargemProdutoSort.normalizeSearchTerm(
          _query.searchTerm,
        ),
        page: _page,
        pageSize: _pageSize,
      ),
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (!mounted || generation != _sqlLoadGeneration) {
      return;
    }

    result.fold(
      (pageResult) {
        final totalPages = pageResult.totalCount <= 0
            ? 0
            : (pageResult.totalCount / _pageSize).ceil();
        if (totalPages > 0 && _page > totalPages) {
          setState(() {
            _page = totalPages;
            _query = SalesMargemProdutoSort.queryFor(
              page: _page,
              pageSize: _pageSize,
              previous: _query,
            );
          });
          unawaited(_loadCatalog());
          return;
        }
        setState(() {
          _rows = pageResult.items;
          _totalCount = pageResult.totalCount;
          _catalogLoading = false;
          _error = null;
          _loadFailure = null;
        });
        markAutoRefreshSuccess();
      },
      (failure) {
        setState(() {
          _catalogLoading = false;
          _rows = const <MargemProdutoRow>[];
          _totalCount = 0;
          _loadFailure = failure;
          _error = _failureMessage(failure, AppLocalizations.of(context));
        });
        onAgentQueryLoadFailure(failure);
        markAutoRefreshFailure();
      },
    );
  }

  String _failureMessage(Object exception, AppLocalizations l10n) {
    return exception is AppFailure
        ? agentQueryFailureUserMessage(exception, l10n)
        : exception.toString();
  }

  String _selectedAgentName(AppLocalizations l10n) {
    final selectedBranch = _availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    return selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
  }

  String _selectedFilialDisplayName(AppLocalizations l10n) {
    if (_selectedFilial == null) {
      return l10n.salesBranchPickerEmpty;
    }
    return salesMargemProdutoFilialLabel(_selectedFilial!);
  }

  ChartShareExportHeaderContext _shareExportHeaderContext(
    AppLocalizations l10n, {
    String? searchTerm,
  }) {
    final parameters = <ChartShareExportHeaderParameter>[
      ChartShareExportHeaderParameter(
        label: l10n.salesMargemProdutoFilterFilial,
        value: _selectedFilialDisplayName(l10n),
      ),
    ];
    final normalizedSearch = SalesMargemProdutoSort.normalizeSearchTerm(
      searchTerm,
    );
    if (normalizedSearch != null) {
      parameters.add(
        ChartShareExportHeaderParameter(
          label: l10n.salesMargemProdutoFilterSearch,
          value: normalizedSearch,
        ),
      );
    }
    return buildSalesSingleAgentChartShareExportHeaderContext(
      l10n: l10n,
      agentName: _selectedAgentName(l10n),
      parameters: parameters,
    );
  }

  Widget _catalogHeaderTrailing(AppLocalizations l10n) {
    return AppChartHeaderTrailing(
      onOpenFullscreen: _canOpenFullscreen ? _openFullscreen : null,
      openFullscreenTooltip: l10n.salesMargemProdutoFullscreenTooltip,
      onShare: _canShare ? () => unawaited(_shareCatalog()) : null,
      shareProgressKey: _shareKey,
      shareEnabled: !_pageLoading,
    );
  }

  void _openFullscreen() {
    if (!_canOpenFullscreen) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: l10n.salesCardMargemProdutoTitle,
          subtitle: l10n.salesMargemProdutoIntroSubtitle,
          filterSummary:
              '${_selectedAgentName(l10n)} · '
              '${_selectedFilialDisplayName(l10n)}',
          chartSemanticsLabel: l10n.salesCardMargemProdutoTitle,
          headerTrailing:
              ValueListenableBuilder<SalesMargemProdutoGridSnapshot>(
                valueListenable: _gridView,
                builder: (context, snapshot, _) {
                  final canShare =
                      !snapshot.isLoading && snapshot.pageInfo.totalRows > 0;
                  return AppChartHeaderTrailing(
                    onShare: canShare ? () => unawaited(_shareCatalog()) : null,
                    shareProgressKey: _shareKey,
                    shareEnabled: !snapshot.isLoading,
                  );
                },
              ),
          chartBuilder: (fullscreenContext) {
            return ValueListenableBuilder<SalesMargemProdutoGridSnapshot>(
              valueListenable: _gridView,
              builder: (context, snapshot, _) {
                return SalesMargemProdutoFullscreen(
                  snapshot: snapshot,
                  onQueryChanged: _onQueryChanged,
                  onPageChanged: _onPageChanged,
                  onPageSizeChanged: _onPageSizeChanged,
                  onRefresh: _loadCatalog,
                  agentId: _selectedAgentId,
                  retryCountdownLabel: agentQueryRetryCountdownLabel(
                    AppLocalizations.of(fullscreenContext),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showShareMessage(String message) {
    if (!mounted || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _shareCatalog() async {
    if (!_canShare) {
      return;
    }
    if (!ChartShareGuard.tryAcquire(_shareKey)) {
      return;
    }

    var transferredToCapture = false;
    try {
      final l10n = AppLocalizations.of(context);
      final auth = context.read<AuthController>();
      final userId = auth.session?.userId;
      final agentId = _selectedAgentId?.trim();
      final filial = _selectedFilial;
      if (userId == null || agentId == null || agentId.isEmpty) {
        _showShareMessage(l10n.agentSqlErrorAuthenticationFailed);
        return;
      }
      if (filial == null) {
        _showShareMessage(l10n.salesMargemProdutoNoBranchEmpty);
        return;
      }

      _shareCancelScope = _replaceCancelScope(_shareCancelScope);
      final shareScope = _shareCancelScope!;
      final totalCount = _totalCount;
      final searchTerm = SalesMargemProdutoSort.normalizeSearchTerm(
        _query.searchTerm,
      );
      final exportHeaderContext = _shareExportHeaderContext(
        l10n,
        searchTerm: searchTerm,
      );

      final clientToken = await _resolveClientToken(
        userId: userId,
        agentId: agentId,
      );
      if (!mounted || shareScope.isCancelled) {
        return;
      }
      if (clientToken == null) {
        _showShareMessage(l10n.agentSqlErrorAuthenticationFailed);
        return;
      }

      final result = await _loadRowsForShare(
        userId: userId,
        agentId: agentId,
        filter: MargemProdutoFilter(
          codEmpresa: filial.codEmpresa,
          codFilial: filial.codFilial,
          searchTerm: searchTerm,
        ),
        totalCount: totalCount,
        clientToken: clientToken,
        cancelScope: shareScope,
      );
      if (!mounted || shareScope.isCancelled) {
        return;
      }

      await result.fold(
        (rows) async {
          ChartShareGuard.release(_shareKey);
          transferredToCapture = true;
          await shareChartCapture(
            context,
            buildSalesMargemProdutoShareMetadata(
              l10n: l10n,
              rows: rows,
              exportHeaderContext: exportHeaderContext,
            ).toShareRequest(_shareKey),
          );
        },
        (failure) async {
          if (shouldSuppressAgentQueryFailureUi(failure)) {
            return;
          }
          final message =
              failure is ValidationFailure &&
                  failure.message == 'share_export_row_limit_exceeded'
              ? l10n.chartShareExportRowLimitExceeded(
                  ChartSharePdfLimits.maxTableRows,
                  totalCount,
                )
              : failure is ValidationFailure &&
                    failure.message == 'share_export_incomplete_catalog'
              ? l10n.chartShareExportIncompleteCatalog
              : _failureMessage(failure, l10n);
          _showShareMessage(message);
        },
      );
    } finally {
      if (!transferredToCapture) {
        ChartShareGuard.release(_shareKey);
      }
    }
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(
      SalesMargemProdutoSort.cardId,
      SalesMargemProdutoSort.persistMap(
        pageSize: _pageSize,
        searchTerm: _query.searchTerm,
        codEmpresa: _selectedFilial?.codEmpresa ?? _preferredCodEmpresa,
        codFilial: _selectedFilial?.codFilial ?? _preferredCodFilial,
      ),
    );
  }

  void _onFiltersChanged(Map<String, Object?> next) {
    _shareCancelScope?.cancelAll();
    final nextAgentId = (next['agentId'] as String?)?.trim();
    final normalizedAgentId = nextAgentId == null || nextAgentId.isEmpty
        ? null
        : nextAgentId;
    final nextEmpresa = SalesMargemProdutoSort.restoreInt(next['codEmpresa']);
    final nextFilial = SalesMargemProdutoSort.restoreInt(next['codFilial']);
    final agentChanged = normalizedAgentId != _selectedAgentId;
    setState(() {
      _selectedAgentId = normalizedAgentId;
      _preferredCodEmpresa = nextEmpresa;
      _preferredCodFilial = nextFilial;
      _page = 1;
      _query = SalesMargemProdutoSort.queryFor(
        page: 1,
        pageSize: _pageSize,
        previous: _query,
      );
      if (agentChanged) {
        _filiais = const <CadastroFilialRow>[];
        _selectedFilial = null;
      }
    });
    unawaited(_sessionService.setSelectedAgentId(normalizedAgentId));
    if (agentChanged) {
      unawaited(_persistFilters());
      unawaited(_loadFiliaisThenCatalog());
      return;
    }
    final matched = salesMargemProdutoFindFilial(
      items: _filiais,
      codEmpresa: nextEmpresa,
      codFilial: nextFilial,
    );
    if (matched == null) {
      setState(() => _selectedFilial = null);
      unawaited(_persistFilters());
      unawaited(_loadFiliaisThenCatalog());
      return;
    }
    setState(() => _selectedFilial = matched);
    unawaited(_persistFilters());
    unawaited(_loadCatalog(clearVisibleCatalog: true));
  }

  void _onPageSizeChanged(int size) {
    _applyPaging(page: 1, pageSize: size, previous: _query);
  }

  void _onPageChanged(int page) {
    _applyPaging(page: page, pageSize: _pageSize, previous: _query);
  }

  void _onQueryChanged(AppReportQuery next) {
    final nextSearch = SalesMargemProdutoSort.normalizeSearchTerm(
      next.searchTerm,
    );
    final currentSearch = SalesMargemProdutoSort.normalizeSearchTerm(
      _query.searchTerm,
    );
    if (nextSearch != currentSearch) {
      _applySearch(nextSearch, previous: next);
      return;
    }
    _applyPaging(page: next.page, pageSize: next.pageSize, previous: next);
  }

  void _applySearch(String? searchTerm, {AppReportQuery? previous}) {
    _shareCancelScope?.cancelAll();
    setState(() {
      _page = 1;
      _query = SalesMargemProdutoSort.queryFor(
        page: 1,
        pageSize: _pageSize,
        searchTerm: searchTerm,
        clearSearchTerm: searchTerm == null,
        previous: previous ?? _query,
      );
    });
    unawaited(_persistFilters());
    unawaited(_loadCatalog(clearVisibleCatalog: true));
  }

  void _applyPaging({
    required int page,
    required int pageSize,
    AppReportQuery? previous,
  }) {
    final sanitizedSize = SalesMargemProdutoSort.sanitizePageSize(pageSize);
    final pageSizeChanged = sanitizedSize != _pageSize;
    final sanitizedPage = pageSizeChanged
        ? 1
        : SalesMargemProdutoSort.sanitizePage(page);
    if (!pageSizeChanged && sanitizedPage == _page) {
      return;
    }

    setState(() {
      _pageSize = sanitizedSize;
      _page = sanitizedPage;
      _query = SalesMargemProdutoSort.queryFor(
        page: sanitizedPage,
        pageSize: sanitizedSize,
        previous: previous ?? _query,
      );
    });
    unawaited(_persistFilters());
    unawaited(_loadCatalog());
  }

  Future<void> _openFiltersSheet() async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) {
        return SalesMargemProdutoFiltersSheet(
          l10n: AppLocalizations.of(context),
          availableAgents: _availableAgents,
          initialSelectedAgentId: _selectedAgentId,
          initialFiliais: _filiais,
          initialCodEmpresa:
              _selectedFilial?.codEmpresa ?? _preferredCodEmpresa,
          initialCodFilial: _selectedFilial?.codFilial ?? _preferredCodFilial,
          loadFiliais: _fetchFiliais,
          onApply: _onFiltersChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final selectedBranchName = _selectedAgentName(l10n);
    final selectedFilialName = _selectedFilialDisplayName(l10n);
    final pageInfo = SalesMargemProdutoSort.pageInfo(
      page: _page,
      pageSize: _pageSize,
      totalCount: _totalCount,
    );

    final Widget reportSurface;
    if (_selectedAgentId == null) {
      reportSurface = AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        title: l10n.salesBranchRequiredTitle,
        message: l10n.salesBranchRequiredMessage,
      );
    } else if (_filiaisFailure != null) {
      reportSurface = AgentQueryErrorPanelFactory.fromFailure(
        _filiaisFailure!,
        l10n,
        onRetry: () => unawaited(_loadFiliaisThenCatalog()),
        retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
        supportContext: AgentQueryFailureSupportContext.environment(
          extra: <String, String>{
            'agentId': ?_selectedAgentId,
            'screen': 'sales_margem_produto',
          },
        ),
      );
    } else if (!_filiaisLoading &&
        _filiais.isEmpty &&
        _error == null &&
        _loadFailure == null) {
      reportSurface = AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        message: l10n.salesMargemProdutoNoBranchEmpty,
        onRetry: () => unawaited(_loadFiliaisThenCatalog()),
      );
    } else if (_error != null &&
        _error!.trim().isNotEmpty &&
        _loadFailure == null &&
        _filiaisFailure == null) {
      reportSurface = AppInlineErrorPanel(
        message: _error!,
        onRetry: () => unawaited(_reload()),
      );
    } else {
      reportSurface = LayoutBuilder(
        builder: (context, constraints) {
          final gridHeight = resolveSalesMargemProdutoGridHeight(
            maxHeight: constraints.maxHeight,
            chromeHeight: kSalesMargemProdutoPageChromeHeight,
            maxGridHeight: kSalesMargemProdutoPageGridMaxHeight,
          );
          return AppReportViewer<MargemProdutoRow>(
            title: l10n.salesCardMargemProdutoTitle,
            contextChips: _selectedFilial == null
                ? null
                : <String>[selectedFilialName],
            headerTrailing: _catalogHeaderTrailing(l10n),
            columns: _columns,
            rows: _rows,
            pageInfo: pageInfo,
            query: _query,
            events: AppReportEvents<MargemProdutoRow>(
              onQueryChanged: _onQueryChanged,
              onPageChanged: _onPageChanged,
              onPageSizeChanged: _onPageSizeChanged,
              onRefresh: _loadCatalog,
            ),
            style:
                AppReportViewerStyle.numericalDetailing(
                  entityLabel: l10n.salesMargemProdutoEntityLabel,
                  gridHeight: gridHeight,
                  frozenColumnsCount: 0,
                  dataRowHeight: kSalesMargemProdutoDataRowHeight,
                ).copyWith(
                  allowSorting: false,
                  trustServerRowOrder: true,
                  showRefreshAction: true,
                  enablePullToRefresh: false,
                  showSearchBar: true,
                  searchDebounce: SalesMargemProdutoSort.searchDebounce,
                  availablePageSizes: SalesMargemProdutoSort.allowedPageSizes,
                  headerRowHeight: kSalesMargemProdutoHeaderRowHeight,
                ),
            isLoading: _pageLoading && _loadFailure == null,
            loadErrorPanel: _loadFailure == null
                ? null
                : AgentQueryErrorPanelFactory.fromFailure(
                    _loadFailure!,
                    l10n,
                    onRetry: () => unawaited(_loadCatalog()),
                    retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
                    supportContext: AgentQueryFailureSupportContext.environment(
                      extra: <String, String>{
                        'agentId': ?_selectedAgentId,
                        'screen': 'sales_margem_produto',
                      },
                    ),
                  ),
            onRetry: () => unawaited(_loadCatalog()),
            emptyMessage: l10n.salesMargemProdutoEmpty,
            searchHintText: l10n.salesMargemProdutoSearchHint,
          );
        },
      );
    }

    return Padding(
      padding: context.pageScrollPadding(
        tokens,
        horizontalAdjustment:
            AppPageSpacingPresets.dashboardHorizontalAdjustment,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppShellPageIntro(
            sectionLabel: l10n.shellNavSalesLabel,
            onSectionLabelTap: () => context.goTo(AppRoute.sales),
            title: l10n.salesCardMargemProdutoTitle,
            subtitle: l10n.salesMargemProdutoIntroSubtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesCardFilterTrigger(
            onTap: () => unawaited(_openFiltersSheet()),
            buttonSemanticsLabel: l10n.reportFiltersButton,
            summaryItems: <SalesCardFilterSummaryItem>[
              SalesCardFilterSummaryItem(
                label: l10n.salesBranchFilterLabel,
                value: selectedBranchName,
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesMargemProdutoFilterFilial,
                value: selectedFilialName,
              ),
            ],
            enabled: !_pageLoading,
          ),
          SizedBox(height: tokens.gapMd),
          SalesAutoRefreshActionsRow(
            value: autoRefreshOption,
            onChanged: setAutoRefreshOption,
            onRefreshNow: () => unawaited(_reload()),
            enabled: canScheduleAutoRefresh,
            lastUpdatedAt: autoRefreshLastUpdatedAt,
            isPaused: autoRefreshIsPaused,
            pauseReason: autoRefreshPauseReason,
            l10n: l10n,
          ),
          SizedBox(height: tokens.sectionSpacing),
          Expanded(child: reportSurface),
        ],
      ),
    );
  }
}
