import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/chart_share_icon_button.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/async_search/sales_produto_dimension_async_search_loaders.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_controller.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_share.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_trend_date_preset.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_chart_nav_grid.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_details_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_summary_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/agent_query_error_panel.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaPage extends StatefulWidget {
  const SalesProdutoTendenciaPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadTrendScreenUseCase,
    required this.loadTrendPageUseCase,
    required this.loadGrupoProdutoOptionsUseCase,
    required this.loadMarcaProdutoOptionsUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final LoadProdutoVendidoTendenciaDeVendaScreenUseCase loadTrendScreenUseCase;
  final LoadProdutoVendidoTendenciaDeVendaUseCase loadTrendPageUseCase;
  final LoadGrupoProdutoOptionsUseCase loadGrupoProdutoOptionsUseCase;
  final LoadMarcaProdutoOptionsUseCase loadMarcaProdutoOptionsUseCase;
  final AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder;

  @override
  State<SalesProdutoTendenciaPage> createState() =>
      _SalesProdutoTendenciaPageState();
}

class _SalesProdutoTendenciaPageState extends State<SalesProdutoTendenciaPage>
    with
        AutoRefreshStateMixin<SalesProdutoTendenciaPage>,
        SalesSingleAgentAutoRefreshMixin<SalesProdutoTendenciaPage>,
        SalesCardAutoRefreshBinding<SalesProdutoTendenciaPage>,
        AgentQueryRetryAfterHost<SalesProdutoTendenciaPage> {
  late final SalesProdutoTendenciaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SalesProdutoTendenciaController(
      sessionService: widget.sessionService,
      loadSalesAvailableAgentsUseCase: widget.loadSalesAvailableAgentsUseCase,
      resolveSalesAgentClientTokenUseCase:
          widget.resolveSalesAgentClientTokenUseCase,
      loadTrendScreenUseCase: widget.loadTrendScreenUseCase,
      loadTrendPageUseCase: widget.loadTrendPageUseCase,
      relayCancelScopeBinder: widget.relayCancelScopeBinder,
    );
    _controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthController>().session?.userId;
      unawaited(_controller.bindUser(userId));
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _reload() => reloadWithAutoRefresh();

  @override
  SalesSessionService get salesSessionService => widget.sessionService;

  @override
  String get salesAutoRefreshCardId => SalesAutoRefreshCardIds.produtoTendencia;

  @override
  String? get autoRefreshSelectedAgentId => _controller.state.selectedAgentId;

  @override
  List<DashboardAgentOption> get autoRefreshAvailableAgents =>
      _controller.state.availableAgents;

  @override
  bool get autoRefreshPageLoading => _controller.state.loading;

  @override
  Future<void> performAutoRefreshReload() async {
    markAutoRefreshCancelled();
    final outcome = await _controller.reload();
    if (!mounted || outcome.isSuperseded) {
      return;
    }
    onAgentQueryLoadFailure(outcome.loadFailure);
    if (outcome.isSuccess) {
      markAutoRefreshSuccess();
      return;
    }
    if (outcome.isFailure) {
      markAutoRefreshFailure();
      return;
    }
    markAutoRefreshCancelled();
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
            ).salesProdutoTendenciaFiltersAppliedSnackbar,
          ),
        ),
      );
    });
  }

  Future<void> _onFiltersChanged(Map<String, Object?> next) async {
    await _controller.applyFilters(next);
    _showFiltersAppliedSnackBar();
  }

  bool _hasActiveDetailFilters(SalesProdutoTendenciaPresentationState state) {
    return state.searchTerm.trim().isNotEmpty ||
        state.classificacao != null ||
        state.codGrupoProduto != null ||
        state.codMarca != null;
  }

  Future<void> _clearDetailFilters() async {
    final state = _controller.state;
    await _controller.applyFilters(<String, Object?>{
      'agentId': state.selectedAgentId,
      'periodoAtual': state.periodoAtual,
      'periodoAnterior': state.periodoAnterior,
      'searchTerm': '',
      'classificacao': null,
      'codGrupoProduto': null,
      'codMarca': null,
      'grupoProdutoLabel': null,
      'marcaProdutoLabel': null,
      'pageSize': state.pageSize,
    });
  }

  bool _isChartReady(
    SalesProdutoTendenciaPresentationState state,
    SalesProdutoTendenciaChartId chartId,
  ) {
    return switch (chartId) {
      SalesProdutoTendenciaChartId.classificacao =>
        state.summaryRows.isNotEmpty,
      SalesProdutoTendenciaChartId.topGainers => state.topGainers.isNotEmpty,
      SalesProdutoTendenciaChartId.topLosers => state.topLosers.isNotEmpty,
    };
  }

  SalesProdutoDimensionLoaderFactory _grupoProdutoLoaderFactory(
    String userId,
  ) {
    final clientTokenUnavailableMessage = AppLocalizations.of(
      context,
    ).salesAsyncSearchClientTokenUnavailable;
    final l10n = AppLocalizations.of(context);
    return (agentIdProvider) => createSalesGrupoProdutoAsyncSearchLoader(
      useCase: widget.loadGrupoProdutoOptionsUseCase,
      userId: userId,
      agentIdProvider: agentIdProvider,
      resolveClientToken: (agentId) => _controller.resolveClientToken(
        userId: userId,
        agentId: agentId,
      ),
      clientTokenUnavailableMessage: clientTokenUnavailableMessage,
      l10n: l10n,
      cancelScope: _controller.sqlCancelScope,
    );
  }

  SalesProdutoDimensionLoaderFactory _marcaProdutoLoaderFactory(
    String userId,
  ) {
    final clientTokenUnavailableMessage = AppLocalizations.of(
      context,
    ).salesAsyncSearchClientTokenUnavailable;
    final l10n = AppLocalizations.of(context);
    return (agentIdProvider) => createSalesMarcaProdutoAsyncSearchLoader(
      useCase: widget.loadMarcaProdutoOptionsUseCase,
      userId: userId,
      agentIdProvider: agentIdProvider,
      resolveClientToken: (agentId) => _controller.resolveClientToken(
        userId: userId,
        agentId: agentId,
      ),
      clientTokenUnavailableMessage: clientTokenUnavailableMessage,
      l10n: l10n,
      cancelScope: _controller.sqlCancelScope,
    );
  }

  Future<void> _openFiltersSheet() async {
    if (!mounted) {
      return;
    }
    final state = _controller.state;
    final userId = _controller.boundUserId ?? '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) {
        final sheetL10n = AppLocalizations.of(context);
        return SalesProdutoTendenciaFiltersSheet(
          l10n: sheetL10n,
          availableAgents: state.availableAgents,
          initialSelectedAgentId: state.selectedAgentId,
          initialPeriodoAtual: state.periodoAtual,
          initialPeriodoAnterior: state.periodoAnterior,
          initialSearchTerm: state.searchTerm,
          initialClassificacao: state.classificacao,
          initialCodGrupoProduto: state.codGrupoProduto,
          initialCodMarca: state.codMarca,
          initialGrupoProdutoLabel: state.grupoProdutoLabel,
          initialMarcaProdutoLabel: state.marcaProdutoLabel,
          initialPageSize: state.pageSize,
          grupoProdutoLoaderFactory: _grupoProdutoLoaderFactory(userId),
          marcaProdutoLoaderFactory: _marcaProdutoLoaderFactory(userId),
          onApply: (next) => unawaited(_onFiltersChanged(next)),
        );
      },
    );
  }

  void _openClassificacaoFullscreen(SalesProdutoTendenciaPresentationState state) {
    final l10n = AppLocalizations.of(context);
    final buckets = List<SalesProdutoTendenciaClassBucket>.of(
      buildSalesProdutoTendenciaSummary(state.summaryRows).buckets,
      growable: false,
    );
    final fullscreenShareKey = GlobalKey();
    final shareTitle = l10n.salesProdutoTendenciaSummaryByClassificacaoTitle;
    final shareMetadata = buildSalesProdutoTendenciaClassificacaoShareMetadata(
      l10n: l10n,
      summaryRows: state.summaryRows,
      buckets: buckets
          .map(
            (bucket) => SalesProdutoTendenciaClassBucket(
              classificacao: bucket.classificacao,
              count: bucket.count,
              impacto: bucket.impacto,
            ),
          )
          .toList(growable: false),
      tokens: context.appTokens,
    );
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: shareTitle,
          subtitle: l10n.salesProdutoTendenciaSummaryByClassificacaoSubtitle,
          chartSemanticsLabel: shareTitle,
          headerTrailing: buildChartFullscreenShareTrailing(
            context: context,
            shareKey: fullscreenShareKey,
            metadata: shareMetadata,
          ),
          chartBuilder: (fullscreenContext) {
            final ft = fullscreenContext.appTokens;
            final fl10n = AppLocalizations.of(fullscreenContext);
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AppComparisonBarChart<SalesProdutoTendenciaClassBucket>(
                    items: buckets,
                    labelBuilder: (b) => salesProdutoTendenciaClassificacaoLabel(
                      fl10n,
                      b.classificacao,
                    ),
                    valueBuilder: (b) => b.count,
                    plotFloorAccessibilityNotice:
                        fl10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        fl10n.chartComparisonExtremeValueSpreadNotice,
                    style: salesTrendHomeLikeComparisonBarChartStyle(
                      tokens: ft,
                      l10n: fl10n,
                      yAxisFormat: NumberFormat.decimalPattern(fl10n.localeName),
                      heightOverride: constraints.maxHeight,
                    ),
                    dataLabelBuilder: (bucket, _) =>
                        NumberFormat.decimalPattern(fl10n.localeName).format(
                          bucket.count,
                        ),
                    tooltipLabelBuilder: (bucket, _) =>
                        '${salesProdutoTendenciaClassificacaoLabel(fl10n, bucket.classificacao)} � '
                        '${bucket.count} � '
                        '${NumberFormat.decimalPattern(fl10n.localeName).format(bucket.impacto.round())}',
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openGainersFullscreen(SalesProdutoTendenciaPresentationState state) {
    final snap = List<ProdutoVendidoTendenciaDeVendaRow>.of(
      state.topGainers,
      growable: false,
    );
    _pushTopMoversChartFullscreen(
      title: AppLocalizations.of(context).salesProdutoTendenciaTopGainersTitle,
      subtitle: AppLocalizations.of(
        context,
      ).salesProdutoTendenciaTopMoversSubtitle,
      items: snap,
      useAbsolutePercentForLosers: false,
    );
  }

  void _onChartSelected(
    SalesProdutoTendenciaPresentationState state,
    SalesProdutoTendenciaChartId chartId,
  ) {
    switch (chartId) {
      case SalesProdutoTendenciaChartId.classificacao:
        _openClassificacaoFullscreen(state);
      case SalesProdutoTendenciaChartId.topGainers:
        _openGainersFullscreen(state);
      case SalesProdutoTendenciaChartId.topLosers:
        _openLosersFullscreen(state);
    }
  }

  void _openLosersFullscreen(SalesProdutoTendenciaPresentationState state) {
    final snap = List<ProdutoVendidoTendenciaDeVendaRow>.of(
      state.topLosers,
      growable: false,
    );
    _pushTopMoversChartFullscreen(
      title: AppLocalizations.of(context).salesProdutoTendenciaTopLosersTitle,
      subtitle: AppLocalizations.of(
        context,
      ).salesProdutoTendenciaTopMoversSubtitle,
      items: snap,
      useAbsolutePercentForLosers: true,
    );
  }

  void _pushTopMoversChartFullscreen({
    required String title,
    required String subtitle,
    required List<ProdutoVendidoTendenciaDeVendaRow> items,
    required bool useAbsolutePercentForLosers,
  }) {
    final fullscreenShareKey = GlobalKey();
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final shareMetadata = useAbsolutePercentForLosers
        ? buildSalesProdutoTendenciaTopLosersShareMetadata(
            l10n: l10n,
            rows: items,
            tokens: tokens,
          )
        : buildSalesProdutoTendenciaTopGainersShareMetadata(
            l10n: l10n,
            rows: items,
            tokens: tokens,
          );
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: title,
          subtitle: subtitle,
          chartSemanticsLabel: title,
          headerTrailing: buildChartFullscreenShareTrailing(
            context: context,
            shareKey: fullscreenShareKey,
            metadata: shareMetadata,
          ),
          chartBuilder: (fullscreenContext) {
            final ft = fullscreenContext.appTokens;
            final fl10n = AppLocalizations.of(fullscreenContext);
            final axisFormat = NumberFormat.decimalPattern(fl10n.localeName);
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AppComparisonBarChart<ProdutoVendidoTendenciaDeVendaRow>(
                    items: items,
                    labelBuilder: (row) => row.nomeProduto,
                    valueBuilder: (row) => useAbsolutePercentForLosers
                        ? row.percentualTendencia.abs()
                        : row.percentualTendencia,
                    plotFloorAccessibilityNotice:
                        fl10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        fl10n.chartComparisonExtremeValueSpreadNotice,
                    style: salesTrendHomeLikeComparisonBarChartStyle(
                      tokens: ft,
                      l10n: fl10n,
                      yAxisFormat: axisFormat,
                      minPlottedValueShareOfMax: 0.03,
                      heightOverride: constraints.maxHeight,
                    ),
                    dataLabelBuilder: (row, _) =>
                        '${row.percentualTendencia.toStringAsFixed(1)}%',
                    tooltipLabelBuilder: (row, _) =>
                        '${row.nomeProduto} � '
                        '${row.percentualTendencia.toStringAsFixed(2)}% � '
                        '${NumberFormat.decimalPattern(fl10n.localeName).format(row.diferenca.round())}',
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String _dateRangeLabel(DateTimeRange range) {
    return '${AppBrFormatters.shortDateFormat.format(range.start)} � '
        '${AppBrFormatters.shortDateFormat.format(range.end)}';
  }

  String _periodDescriptorLabel(AppLocalizations l10n, DateTimeRange range) {
    return salesTrendRangeDescriptorLabel(l10n, range);
  }

  List<String> _activeFilterChipLabels(
    AppLocalizations l10n,
    SalesProdutoTendenciaPresentationState state,
  ) {
    final labels = <String>[];
    final trimmedSearch = state.searchTerm.trim();
    if (trimmedSearch.isNotEmpty) {
      labels.add('${l10n.salesProdutoTendenciaFilterSearch}: $trimmedSearch');
    }
    if (state.classificacao != null) {
      labels.add(
        '${l10n.salesProdutoTendenciaFilterClassification}: '
        '${salesProdutoTendenciaClassificacaoLabel(l10n, state.classificacao)}',
      );
    }
    if (state.codGrupoProduto != null) {
      final grupoLabel =
          state.grupoProdutoLabel ?? '#${state.codGrupoProduto}';
      labels.add('${l10n.salesProdutoTendenciaFilterGroup}: $grupoLabel');
    }
    if (state.codMarca != null) {
      final marcaLabel = state.marcaProdutoLabel ?? '#${state.codMarca}';
      labels.add('${l10n.salesProdutoTendenciaFilterBrand}: $marcaLabel');
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;
    final selectedBranch = state.availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == state.selectedAgentId,
          orElse: () => null,
        );
    final selectedBranchName =
        selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
    final activeFilterChipLabels = _activeFilterChipLabels(l10n, state);
    final activeDetailFilterCount = activeFilterChipLabels.length;

    return RefreshIndicator(
      onRefresh: () async {
        await _reload();
      },
      child: ListView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(5000),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.pageScrollPadding(
          tokens,
          horizontalAdjustment:
              AppPageSpacingPresets.dashboardHorizontalAdjustment,
        ),
        children: <Widget>[
            AppShellPageIntro(
              sectionLabel: l10n.shellNavSalesLabel,
              onSectionLabelTap: () => context.goTo(AppRoute.sales),
              title: l10n.salesCardProdutoTendenciaTitle,
              subtitle: l10n.salesProdutoTendenciaPageSubtitle,
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
                  label: l10n.salesProdutoTendenciaFilterCurrentPeriod,
                  value: _dateRangeLabel(state.periodoAtual),
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.salesProdutoTendenciaFilterPreviousPeriod,
                  value: _dateRangeLabel(state.periodoAnterior),
                ),
                SalesCardFilterSummaryItem(
                  label: l10n.reportFiltersTitle,
                  value: l10n.salesProdutoTendenciaActiveFiltersSummary(
                    activeDetailFilterCount,
                  ),
                ),
              ],
              enabled: !state.loading,
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
            if (activeFilterChipLabels.isNotEmpty) ...<Widget>[
              SizedBox(height: tokens.gapMd),
              Wrap(
                spacing: tokens.gapSm,
                runSpacing: tokens.gapSm,
                children: activeFilterChipLabels
                    .map((label) => AppTagChip(label: label))
                    .toList(growable: false),
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            if (state.selectedAgentId == null) ...<Widget>[
              AppInlineErrorPanel(
                tone: AppInlinePanelTone.informational,
                title: l10n.salesBranchRequiredTitle,
                message: l10n.salesBranchRequiredMessage,
              ),
            ] else if (state.loadFailure != null) ...<Widget>[
              AgentQueryErrorPanel.fromFailure(
                state.loadFailure!,
                l10n,
                onRetry: () => unawaited(_reload()),
                retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
                supportContext: AgentQueryFailureSupportContext.environment(
                  extra: <String, String>{
                    'agentId': ?state.selectedAgentId,
                    'screen': 'sales_produto_tendencia',
                  },
                ),
              ),
            ] else if (state.authenticationFailed) ...<Widget>[
              AppInlineErrorPanel(
                message: l10n.agentSqlErrorAuthenticationFailed,
                onRetry: () => unawaited(_reload()),
              ),
            ] else ...<Widget>[
              SalesProdutoTendenciaSummarySection(
                l10n: l10n,
                summaryRows: state.summaryRows,
                loading: state.loading,
                periodoAtual: state.periodoAtual,
                periodoAnterior: state.periodoAnterior,
                periodoAtualDescriptor: _periodDescriptorLabel(
                  l10n,
                  state.periodoAtual,
                ),
                periodoAnteriorDescriptor: _periodDescriptorLabel(
                  l10n,
                  state.periodoAnterior,
                ),
                hasActiveDetailFilters: _hasActiveDetailFilters(state),
                onClearFilters: () => unawaited(_clearDetailFilters()),
                onOpenFilters: () => unawaited(_openFiltersSheet()),
              ),
              SizedBox(height: tokens.sectionSpacing),
              SalesProdutoTendenciaChartNavGrid(
                l10n: l10n,
                loading: state.loading,
                sectionTitle: l10n.salesProdutoTendenciaChartsSectionTitle,
                isChartReady: (chartId) => _isChartReady(state, chartId),
                onChartSelected: (chartId) =>
                    _onChartSelected(state, chartId),
              ),
              SizedBox(height: tokens.sectionSpacing),
              SalesProdutoTendenciaDetailsSection(
                l10n: l10n,
                rows: state.rows,
                totalCount: state.totalCount,
                loading: state.loading,
                currentPage: state.page,
                pageSize: state.pageSize,
                onPageSelected: (page) =>
                    unawaited(_controller.selectPage(page)),
                onPageSizeChanged: (size) =>
                    unawaited(_controller.changePageSize(size)),
                classLabelBuilder: (value) =>
                    salesProdutoTendenciaClassificacaoLabel(l10n, value),
                hasActiveDetailFilters: _hasActiveDetailFilters(state),
                onClearFilters: () => unawaited(_clearDetailFilters()),
                onOpenFilters: () => unawaited(_openFiltersSheet()),
              ),
            ],
        ],
      ),
    );
  }
}
