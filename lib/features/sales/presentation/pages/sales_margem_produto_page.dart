import 'dart:async';

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
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_error_panel_factory.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_columns.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:colmeia/shared/widgets/reports/app_report_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';

const double _kMargemProdutoChromeHeight = 176;
const double _kMargemProdutoGridMinHeight = 240;
const double _kMargemProdutoGridMaxHeight = 720;
const double _kMargemProdutoDataRowHeight = 48;
const double _kMargemProdutoHeaderRowHeight = 40;

class SalesMargemProdutoPage extends StatefulWidget {
  const SalesMargemProdutoPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadCadastroFilialPageUseCase,
    required this.loadMargemProdutoPageUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final LoadCadastroFilialPageUseCase loadCadastroFilialPageUseCase;
  final LoadMargemProdutoPageUseCase loadMargemProdutoPageUseCase;
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

  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = <DashboardAgentOption>[];
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  List<CadastroFilialRow> _filiais = const <CadastroFilialRow>[];
  CadastroFilialRow? _selectedFilial;
  int? _preferredCodEmpresa;
  int? _preferredCodFilial;

  MargemProdutoSortBy _sortBy = SalesMargemProdutoSort.defaultSortBy;
  ResumoProdutoVendaSortDirection _sortDirection =
      SalesMargemProdutoSort.defaultSortDirection;
  int _page = 1;
  int _pageSize = SalesMargemProdutoSort.defaultPageSize;
  AppReportQuery _query = const AppReportQuery(
    sorts: <AppReportSortDescriptor>[
      AppReportSortDescriptor(
        columnKey: SalesMargemProdutoSort.columnMargem,
        direction: AppReportSortDirection.descending,
      ),
    ],
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
  AgentQueriesCancelScope? _sqlCancelScope;

  bool get _pageLoading => _filiaisLoading || _catalogLoading;

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

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService;
    _resolveClientTokenUseCase = widget.resolveSalesAgentClientTokenUseCase;
    _loadAgentsUseCase = widget.loadSalesAvailableAgentsUseCase;
    _loadCadastroFilial = widget.loadCadastroFilialPageUseCase;
    _loadMargemProduto = widget.loadMargemProdutoPageUseCase;
    _selectedAgentId = _sessionService.selectedAgentId;

    final restored = SalesMargemProdutoSort.restore(
      _sessionService.restoreCardFilters(SalesMargemProdutoSort.cardId),
    );
    _sortBy = restored.sortBy;
    _sortDirection = restored.sortDirection;
    _pageSize = restored.pageSize;
    _preferredCodEmpresa = restored.codEmpresa;
    _preferredCodFilial = restored.codFilial;
    _query = SalesMargemProdutoSort.queryFor(
      sortBy: _sortBy,
      sortDirection: _sortDirection,
      page: 1,
      pageSize: _pageSize,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAgents());
    });
  }

  @override
  void dispose() {
    _sqlCancelScope?.cancelAll();
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
    if (userId == null) {
      return const Success(<CadastroFilialRow>[]);
    }

    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (clientToken == null) {
      return const Success(<CadastroFilialRow>[]);
    }

    final result = await _loadCadastroFilial(
      userId: userId,
      agentId: agentId,
      filter: const CadastroFilialFilter(
        pageSize: CadastroFilialFilter.maxPageSize,
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

    _sqlCancelScope?.cancelAll();
    final sqlScope = AgentQueriesCancelScope();
    _sqlCancelScope = sqlScope;
    widget.relayCancelScopeBinder?.call(sqlScope);

    setState(() {
      _filiaisLoading = true;
      _filiaisFailure = null;
      _error = null;
      _loadFailure = null;
    });

    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    if (userId == null) {
      if (!mounted || generation != _filiaisGeneration) {
        return;
      }
      setState(() {
        _filiaisLoading = false;
      });
      return;
    }

    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (!mounted || generation != _filiaisGeneration) {
      return;
    }
    if (clientToken == null) {
      setState(() {
        _filiaisLoading = false;
        _filiais = const <CadastroFilialRow>[];
        _selectedFilial = null;
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
        _error = AppLocalizations.of(context).agentSqlErrorAuthenticationFailed;
      });
      markAutoRefreshCancelled();
      return;
    }

    final result = await _fetchFiliais(agentId, cancelScope: sqlScope);
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
    });
    if (selected == null) {
      setState(() {
        _catalogLoading = false;
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
      });
      return;
    }
    await _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    markAutoRefreshCancelled();
    final generation = ++_sqlLoadGeneration;
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId?.trim();
    final filial = _selectedFilial;

    setState(() {
      _catalogLoading = true;
      _error = null;
      _loadFailure = null;
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
      setState(() {
        _catalogLoading = false;
        _rows = const <MargemProdutoRow>[];
        _totalCount = 0;
        _error = AppLocalizations.of(context).agentSqlErrorAuthenticationFailed;
      });
      markAutoRefreshCancelled();
      return;
    }

    final result = await _loadMargemProduto(
      userId: userId,
      agentId: agentId,
      filter: MargemProdutoFilter(
        codEmpresa: filial.codEmpresa,
        codFilial: filial.codFilial,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        page: _page,
        pageSize: _pageSize,
      ),
      clientToken: clientToken,
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
          _page = totalPages;
          _query = SalesMargemProdutoSort.queryFor(
            sortBy: _sortBy,
            sortDirection: _sortDirection,
            page: _page,
            pageSize: _pageSize,
            previous: _query,
          );
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

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(
      SalesMargemProdutoSort.cardId,
      SalesMargemProdutoSort.persistMap(
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        pageSize: _pageSize,
        codEmpresa: _selectedFilial?.codEmpresa ?? _preferredCodEmpresa,
        codFilial: _selectedFilial?.codFilial ?? _preferredCodFilial,
      ),
    );
  }

  void _onFiltersChanged(Map<String, Object?> next) {
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
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        page: 1,
        pageSize: _pageSize,
        previous: _query,
      );
    });
    unawaited(_sessionService.setSelectedAgentId(normalizedAgentId));
    unawaited(_persistFilters());
    if (agentChanged) {
      unawaited(_loadFiliaisThenCatalog());
      return;
    }
    final matched = salesMargemProdutoMatchFilial(
      items: _filiais,
      codEmpresa: nextEmpresa,
      codFilial: nextFilial,
    );
    setState(() => _selectedFilial = matched);
    unawaited(_loadCatalog());
  }

  void _onQueryChanged(AppReportQuery next) {
    final (sortBy, sortDirection) = SalesMargemProdutoSort.fromSorts(
      next.sorts,
    );
    final pageSize = SalesMargemProdutoSort.sanitizePageSize(next.pageSize);
    final sortsChanged = sortBy != _sortBy || sortDirection != _sortDirection;
    final pageSizeChanged = pageSize != _pageSize;
    final page = (sortsChanged || pageSizeChanged)
        ? 1
        : SalesMargemProdutoSort.sanitizePage(next.page);
    final needsReload = sortsChanged || pageSizeChanged || page != _page;
    if (!needsReload) {
      return;
    }

    final sanitized = SalesMargemProdutoSort.queryFor(
      sortBy: sortBy,
      sortDirection: sortDirection,
      page: page,
      pageSize: pageSize,
      previous: next,
    );
    setState(() {
      _sortBy = sortBy;
      _sortDirection = sortDirection;
      _pageSize = pageSize;
      _page = page;
      _query = sanitized;
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
    final selectedBranch = _availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final selectedBranchName =
        selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
    final selectedFilialName = _selectedFilial == null
        ? l10n.salesBranchPickerEmpty
        : salesMargemProdutoFilialLabel(_selectedFilial!);
    final columns = buildSalesMargemProdutoColumns(
      labels: SalesMargemProdutoColumnLabels.fromL10n(l10n),
    );
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
          final gridHeight =
              (constraints.maxHeight - _kMargemProdutoChromeHeight).clamp(
                _kMargemProdutoGridMinHeight,
                _kMargemProdutoGridMaxHeight,
              );
          return AppReportViewer<MargemProdutoRow>(
            title: l10n.salesCardMargemProdutoTitle,
            contextChips: _selectedFilial == null
                ? null
                : <String>[selectedFilialName],
            columns: columns,
            rows: _rows,
            pageInfo: pageInfo,
            query: _query,
            events: AppReportEvents<MargemProdutoRow>(
              onQueryChanged: _onQueryChanged,
              onRefresh: _loadCatalog,
            ),
            style:
                AppReportViewerStyle.numericalDetailing(
                  entityLabel: l10n.salesMargemProdutoEntityLabel,
                  gridHeight: gridHeight,
                  frozenColumnsCount: 0,
                  dataRowHeight: _kMargemProdutoDataRowHeight,
                ).copyWith(
                  trustServerRowOrder: true,
                  showRefreshAction: true,
                  enablePullToRefresh: false,
                  availablePageSizes: SalesMargemProdutoSort.allowedPageSizes,
                  headerRowHeight: _kMargemProdutoHeaderRowHeight,
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
