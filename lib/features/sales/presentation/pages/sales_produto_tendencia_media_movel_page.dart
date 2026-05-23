import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_media_movel_widgets.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaMediaMovelPage extends StatefulWidget {
  const SalesProdutoTendenciaMediaMovelPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadTrendScreenUseCase,
    required this.loadGrupoProdutoOptionsUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadSalesAvailableAgentsUseCase loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
  loadTrendScreenUseCase;
  final LoadGrupoProdutoOptionsUseCase loadGrupoProdutoOptionsUseCase;
  final AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder;

  @override
  State<SalesProdutoTendenciaMediaMovelPage> createState() =>
      _SalesProdutoTendenciaMediaMovelPageState();
}

class _SalesProdutoTendenciaMediaMovelPageState
    extends State<SalesProdutoTendenciaMediaMovelPage>
    with
        AutoRefreshStateMixin<SalesProdutoTendenciaMediaMovelPage>,
        SalesSingleAgentAutoRefreshMixin<SalesProdutoTendenciaMediaMovelPage>,
        SalesCardAutoRefreshBinding<SalesProdutoTendenciaMediaMovelPage> {
  static const String _cardId = 'produto_tendencia_venda_media_movel';
  static const List<int> _pageSizeOptions = <int>[10, 20, 50, 100];

  late final SalesSessionService _sessionService;
  late final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;
  late final LoadSalesAvailableAgentsUseCase _loadAgentsUseCase;
  late final LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
  _loadTrendScreen;
  late final LoadGrupoProdutoOptionsUseCase _loadGrupoOptions;

  String? _selectedAgentId;
  List<OverviewAgentOption> _availableAgents = <OverviewAgentOption>[];
  List<GrupoProdutoOption> _grupoOptions = const <GrupoProdutoOption>[];
  String? _optionsLoadedForAgentId;

  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  int _quantidadeDias = 7;
  String _searchTerm = '';
  String? _classificacao;
  int? _codGrupoProduto;
  ProdutoVendidoTendenciaDeVendaMediaMovelSortBy _sortBy =
      ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc;
  int _page = 1;
  int _pageSize =
      ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize;

  bool _loading = false;
  String? _error;
  int _sqlLoadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;
  String? _summaryError;
  ProdutoVendidoTendenciaDeVendaMediaMovelPageResult _pageResult =
      const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
        items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
        totalCount: 0,
      );
  List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> _summaryRows =
      const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[];

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService;
    _resolveClientTokenUseCase = widget.resolveSalesAgentClientTokenUseCase;
    _loadAgentsUseCase = widget.loadSalesAvailableAgentsUseCase;
    _loadTrendScreen = widget.loadTrendScreenUseCase;
    _loadGrupoOptions = widget.loadGrupoProdutoOptionsUseCase;
    _selectedAgentId = _sessionService.selectedAgentId;

    final restored = _sessionService.restoreCardFilters(_cardId);
    _quantidadeDias =
        _restorePositiveInt(restored['quantidade_dias'])?.clamp(
          1,
          ProdutoVendidoTendenciaDeVendaMediaMovelFilter.maxQuantidadeDias,
        ) ??
        7;
    _searchTerm = (restored['search_term'] as String?)?.trim() ?? '';
    final restoredClassificacao = (restored['classificacao'] as String?)
        ?.trim()
        .toUpperCase();
    _classificacao =
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.allowedClassificacoes
            .contains(restoredClassificacao)
        ? restoredClassificacao
        : null;
    _codGrupoProduto = _restorePositiveInt(restored['cod_grupo_produto']);

    final restoredSortByName = (restored['sort_by'] as String?)?.trim();
    _sortBy = ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.values.firstWhere(
      (value) => value.name == restoredSortByName,
      orElse: () => ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
          .tendenciaPercentualDesc,
    );

    final restoredPageSize = _restorePositiveInt(restored['page_size']);
    if (restoredPageSize != null &&
        _pageSizeOptions.contains(restoredPageSize)) {
      _pageSize = restoredPageSize;
    }

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
    unawaited(_reload());
  }

  Future<void> _reload() => reloadWithAutoRefresh();

  @override
  SalesSessionService get salesSessionService => _sessionService;

  @override
  String get salesAutoRefreshCardId =>
      SalesAutoRefreshCardIds.produtoTendenciaMediaMovel;

  @override
  String? get autoRefreshSelectedAgentId => _selectedAgentId;

  @override
  List<OverviewAgentOption> get autoRefreshAvailableAgents => _availableAgents;

  @override
  bool get autoRefreshPageLoading => _loading;

  @override
  Future<void> performAutoRefreshReload() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId;
    markAutoRefreshCancelled();

    final generation = ++_sqlLoadGeneration;
    _sqlCancelScope?.cancelAll();
    final sqlScope = AgentQueriesCancelScope();
    _sqlCancelScope = sqlScope;
    widget.relayCancelScopeBinder?.call(sqlScope);

    setState(() {
      _loading = true;
      _error = null;
      _summaryError = null;
    });

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _pageResult = const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
          totalCount: 0,
        );
        _summaryRows =
            const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[];
      });
      return;
    }

    final trimmedAgentId = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmedAgentId,
    );
    if (!mounted || generation != _sqlLoadGeneration) {
      return;
    }
    if (clientToken == null) {
      setState(() {
        _loading = false;
        _pageResult = const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
          totalCount: 0,
        );
        _summaryRows =
            const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[];
        _error = AppLocalizations.of(context).agentSqlErrorAuthenticationFailed;
      });
      markAutoRefreshCancelled();
      return;
    }

    if (_optionsLoadedForAgentId != trimmedAgentId) {
      await _loadDimensionOptions(
        userId: userId,
        agentId: trimmedAgentId,
        clientToken: clientToken,
      );
      if (!mounted || generation != _sqlLoadGeneration) {
        return;
      }
    }

    final filter = ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
      quantidadeDias: _quantidadeDias,
      searchTerm: _searchTerm,
      classificacao: _classificacao,
      codGrupoProduto: _codGrupoProduto,
      sortBy: _sortBy,
      page: _page,
      pageSize: _pageSize,
    );

    final screenResult = await _loadTrendScreen(
      userId: userId,
      agentId: trimmedAgentId,
      filter: filter,
      clientToken: clientToken,
      cancelScope: sqlScope,
    );

    if (!mounted || generation != _sqlLoadGeneration) {
      return;
    }

    screenResult.fold(
      (data) {
        setState(() {
          _pageResult = data.page;
          _summaryRows = data.summaryRows;
          _loading = false;
          _error = null;
          _summaryError = null;
        });
        markAutoRefreshSuccess();
      },
      (failure) {
        setState(() {
          _pageResult =
              const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
                items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
                totalCount: 0,
              );
          _summaryRows =
              const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[];
          _loading = false;
          _error = _failureMessage(failure);
          _summaryError = null;
        });
        markAutoRefreshFailure();
      },
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
    _cachedClientTokenUserId = userId;
    _cachedClientTokenAgentId = agentId;
    return _cachedClientToken = resolved;
  }

  Future<void> _loadDimensionOptions({
    required String userId,
    required String agentId,
    required String clientToken,
  }) async {
    final grupoFuture = _loadGrupoOptions(
      userId: userId,
      agentId: agentId,
      pageSize: 200,
      clientToken: clientToken,
    );
    final grupoResult = await grupoFuture;
    if (!mounted) {
      return;
    }

    final nextGrupos = grupoResult.fold(
      (options) => options,
      (_) => const <GrupoProdutoOption>[],
    );

    setState(() {
      _grupoOptions = nextGrupos;
      _optionsLoadedForAgentId = agentId;
    });
  }

  String _failureMessage(Object failure) {
    final err = failure;
    return err is AppFailure ? err.displayMessage : failure.toString();
  }

  int? _restorePositiveInt(Object? raw) {
    final value = raw is int ? raw : int.tryParse('$raw');
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  Future<void> _onAgentChanged(String agentId) async {
    setState(() {
      _selectedAgentId = agentId;
      _page = 1;
    });
    await _sessionService.setSelectedAgentId(agentId);
    if (!mounted) {
      return;
    }
    await _reload();
  }

  Future<void> _persistFilters() {
    return _sessionService.persistCardFilters(_cardId, <String, Object?>{
      'quantidade_dias': _quantidadeDias,
      'search_term': _searchTerm,
      'classificacao': _classificacao,
      'cod_grupo_produto': _codGrupoProduto,
      'sort_by': _sortBy.name,
      'page_size': _pageSize,
    });
  }

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => SalesProdutoTendenciaMediaMovelFiltersSheet(
        l10n: l10n,
        availableAgents: _availableAgents,
        initialSelectedAgentId: _selectedAgentId,
        initialQuantidadeDias: _quantidadeDias,
        initialSearchTerm: _searchTerm,
        initialClassificacao: _classificacao,
        initialCodGrupoProduto: _codGrupoProduto,
        initialSortBy: _sortBy,
        initialPageSize: _pageSize,
        grupoOptions: _grupoOptions,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final nextSortByName = result['sortBy'] as String?;
    final nextSortBy = ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.values
        .firstWhere(
          (value) => value.name == nextSortByName,
          orElse: () => _sortBy,
        );

    setState(() {
      _selectedAgentId = result['agentId'] as String?;
      _quantidadeDias = (result['quantidadeDias'] as int?) ?? _quantidadeDias;
      _searchTerm = (result['searchTerm'] as String?)?.trim() ?? '';
      _classificacao = result['classificacao'] as String?;
      _codGrupoProduto = result['codGrupoProduto'] as int?;
      _sortBy = nextSortBy;
      _pageSize = (result['pageSize'] as int?) ?? _pageSize;
      _page = 1;
    });
    await _sessionService.setSelectedAgentId(_selectedAgentId);
    await _persistFilters();
    if (!mounted) {
      return;
    }
    _showFiltersAppliedSnackBar();
    await _reload();
  }

  void _showFiltersAppliedSnackBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).salesProdutoTendenciaMediaMovelFiltersAppliedSnackbar,
          ),
        ),
      );
    });
  }

  Future<void> _goToPage(int page) async {
    if (page == _page || page < 1) {
      return;
    }
    setState(() => _page = page);
    await _reload();
  }

  Future<void> _changePageSize(int pageSize) async {
    if (pageSize == _pageSize) {
      return;
    }
    setState(() {
      _pageSize = pageSize;
      _page = 1;
    });
    await _persistFilters();
    if (!mounted) {
      return;
    }
    await _reload();
  }

  int get _activeFilterCount {
    var count = 0;
    if (_searchTerm.trim().isNotEmpty) {
      count++;
    }
    if (_classificacao != null) {
      count++;
    }
    if (_codGrupoProduto != null) {
      count++;
    }
    if (_sortBy !=
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
            .tendenciaPercentualDesc) {
      count++;
    }
    if (_pageSize !=
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final selectedBranch = _availableAgents
        .cast<OverviewAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final summary = buildSalesProdutoTendenciaMediaMovelSummary(_summaryRows);
    final hasRows = _pageResult.items.isNotEmpty;
    final hasSummary = _summaryError == null && _summaryRows.isNotEmpty;
    final hasAnyData = hasRows || _summaryRows.isNotEmpty;
    final totalPages = _pageResult.totalCount == 0
        ? 0
        : (_pageResult.totalCount / _pageSize).ceil();
    final rangeStart = _pageResult.totalCount == 0
        ? 0
        : ((_page - 1) * _pageSize) + 1;
    final rangeEnd = _pageResult.totalCount == 0
        ? 0
        : math.min(_page * _pageSize, _pageResult.totalCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(l10n.salesCardProdutoTendenciaMediaMovelTitle),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: context.pageScrollPadding(tokens),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppShellPageIntro(
                    sectionLabel: l10n.shellNavSalesLabel,
                    onSectionLabelTap: () => context.goTo(AppRoute.sales),
                    subtitle: l10n.salesProdutoTendenciaMediaMovelPageSubtitle,
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  SalesBranchPickerControl(
                    l10n: l10n,
                    availableBranches: _availableAgents,
                    selectedBranchId: _selectedAgentId,
                    onSelectionChanged: (agentId) {
                      unawaited(_onAgentChanged(agentId));
                    },
                  ),
                  SizedBox(height: tokens.gapMd),
                  SalesCardFilterTrigger(
                    summaryItems: <SalesCardFilterSummaryItem>[
                      SalesCardFilterSummaryItem(
                        label: l10n.salesBranchFilterLabel,
                        value:
                            selectedBranch?.name ??
                            l10n.salesBranchRequiredMessage,
                      ),
                      SalesCardFilterSummaryItem(
                        label: l10n
                            .salesProdutoTendenciaMediaMovelFilterQuantidadeDias,
                        value: l10n
                            .salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(
                              _quantidadeDias,
                            ),
                      ),
                      SalesCardFilterSummaryItem(
                        label: l10n.salesProdutoTendenciaMediaMovelFilterSortBy,
                        value: produtoTendenciaMediaMovelSortLabel(
                          l10n,
                          _sortBy,
                        ),
                      ),
                      SalesCardFilterSummaryItem(
                        label: l10n.reportFiltersTitle,
                        value: l10n
                            .salesProdutoTendenciaMediaMovelActiveFiltersSummary(
                              _activeFilterCount,
                            ),
                      ),
                    ],
                    onTap: _openFilters,
                    buttonSemanticsLabel: l10n.reportFiltersTitleWithContext(
                      l10n.salesCardProdutoTendenciaMediaMovelTitle,
                    ),
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
                  if (_selectedAgentId == null ||
                      _selectedAgentId!.trim().isEmpty) ...<Widget>[
                    SizedBox(height: tokens.sectionSpacing),
                    AppInlineErrorPanel(
                      tone: AppInlinePanelTone.informational,
                      title: l10n.salesBranchRequiredTitle,
                      message:
                          l10n.salesProdutoTendenciaMediaMovelSelectAgentHint,
                    ),
                  ] else if (_error != null) ...<Widget>[
                    SizedBox(height: tokens.sectionSpacing),
                    AppInlineErrorPanel(
                      title: l10n.salesProdutoTendenciaMediaMovelDetailsTitle,
                      message: _error!,
                      onRetry: _reload,
                    ),
                  ] else if (_loading) ...<Widget>[
                    SizedBox(height: tokens.sectionSpacing),
                    SalesProdutoTendenciaMediaMovelLoadingSection(
                      title: l10n.salesProdutoTendenciaMediaMovelSummaryTitle,
                      subtitle:
                          l10n.salesProdutoTendenciaMediaMovelSummarySubtitle,
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    SalesProdutoTendenciaMediaMovelLoadingSection(
                      title: l10n
                          .salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle,
                      subtitle: l10n
                          .salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle,
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    SalesProdutoTendenciaMediaMovelLoadingSection(
                      title: l10n.salesProdutoTendenciaMediaMovelDetailsTitle,
                      subtitle:
                          l10n.salesProdutoTendenciaMediaMovelDetailsSubtitle,
                    ),
                  ] else if (!hasAnyData) ...<Widget>[
                    SizedBox(height: tokens.sectionSpacing),
                    AppInlineErrorPanel(
                      tone: AppInlinePanelTone.informational,
                      title: l10n.salesProdutoTendenciaMediaMovelSummaryTitle,
                      message: l10n.salesProdutoTendenciaMediaMovelNoData,
                    ),
                  ] else ...<Widget>[
                    if (_summaryError != null) ...<Widget>[
                      SizedBox(height: tokens.sectionSpacing),
                      AppInlineErrorPanel(
                        tone: AppInlinePanelTone.informational,
                        title: l10n
                            .salesProdutoTendenciaMediaMovelSummaryUnavailableTitle,
                        message: l10n
                            .salesProdutoTendenciaMediaMovelSummaryUnavailableMessage,
                      ),
                    ],
                    if (hasSummary) ...<Widget>[
                      SizedBox(height: tokens.sectionSpacing),
                      SalesProdutoTendenciaMediaMovelSummarySection(
                        l10n: l10n,
                        summary: summary,
                      ),
                      SizedBox(height: tokens.sectionSpacing),
                      SalesProdutoTendenciaMediaMovelCountChartSection(
                        l10n: l10n,
                        buckets: summary.buckets,
                      ),
                      SizedBox(height: tokens.sectionSpacing),
                      SalesProdutoTendenciaMediaMovelImpactChartSection(
                        l10n: l10n,
                        buckets: summary.buckets,
                      ),
                    ],
                    SizedBox(height: tokens.sectionSpacing),
                    SalesProdutoTendenciaMediaMovelDetailsSection(
                      l10n: l10n,
                      rows: _pageResult.items,
                      totalCount: _pageResult.totalCount,
                      pageSize: _pageSize,
                      currentPage: _page,
                      totalPages: totalPages,
                      rangeStart: rangeStart,
                      rangeEnd: rangeEnd,
                      sortBy: _sortBy,
                      onPageSelected: (page) {
                        unawaited(_goToPage(page));
                      },
                      onNext: _page < totalPages
                          ? () => unawaited(_goToPage(_page + 1))
                          : null,
                      onPrevious: _page > 1
                          ? () => unawaited(_goToPage(_page - 1))
                          : null,
                      onPageSizeChanged: (value) {
                        unawaited(_changePageSize(value));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
