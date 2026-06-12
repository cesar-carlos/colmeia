import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_chart_share_actions.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/chart_share_icon_button.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/load_media_movel_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/async_search/sales_produto_dimension_async_search_loaders.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_media_movel_controller.dart';
import 'package:colmeia/features/sales/presentation/share/sales_chart_share_export_filter.dart';
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_media_movel_share.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_media_movel_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_auto_refresh_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_body_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_chart_nav_grid.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_chart_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_filter_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_scroll_tokens.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SalesProdutoTendenciaMediaMovelPage extends StatefulWidget {
  const SalesProdutoTendenciaMediaMovelPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadTrendScreenUseCase,
    required this.loadTrendPageUseCase,
    required this.loadGrupoProdutoOptionsUseCase,
    required this.loadMarcaProdutoOptionsUseCase,
    required this.loadRowsForShareUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
  loadTrendScreenUseCase;
  final LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase
  loadTrendPageUseCase;
  final LoadGrupoProdutoOptionsUseCase loadGrupoProdutoOptionsUseCase;
  final LoadMarcaProdutoOptionsUseCase loadMarcaProdutoOptionsUseCase;
  final LoadMediaMovelRowsForShareUseCase loadRowsForShareUseCase;
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
        SalesCardAutoRefreshBinding<SalesProdutoTendenciaMediaMovelPage>,
        AgentQueryRetryAfterHost<SalesProdutoTendenciaMediaMovelPage> {
  late final SalesProdutoTendenciaMediaMovelController _controller;
  late final LoadMediaMovelRowsForShareUseCase _loadRowsForShare;

  final GlobalKey _detailsShareKey = GlobalKey();
  final GlobalKey _detailsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadRowsForShare = widget.loadRowsForShareUseCase;
    _controller = SalesProdutoTendenciaMediaMovelController(
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
    if (!mounted) {
      return;
    }
    refreshAutoRefreshScheduling();
  }

  @override
  bool get rebuildOnAutoRefreshStateChange => false;

  Future<void> _reload() => reloadWithAutoRefresh();

  @override
  SalesSessionService get salesSessionService => widget.sessionService;

  @override
  String get salesAutoRefreshCardId =>
      SalesAutoRefreshCardIds.produtoTendenciaMediaMovel;

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

  String _failureMessage(Object failure, AppLocalizations l10n) {
    return failure is AppFailure
        ? agentQueryFailureUserMessage(failure, l10n)
        : failure.toString();
  }

  Future<void> _onFiltersChanged(Map<String, Object?> next) async {
    await _controller.applyFilters(next);
    _showFiltersAppliedSnackBar();
  }

  Future<void> _clearDetailFilters() async {
    final state = _controller.state;
    await _controller.applyFilters(<String, Object?>{
      'agentId': state.selectedAgentId,
      'quantidadeDias': state.quantidadeDias,
      'searchTerm': '',
      'classificacao': null,
      'codGrupoProduto': null,
      'codMarca': null,
      'grupoProdutoLabel': null,
      'marcaProdutoLabel': null,
      'sortBy': ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
          .tendenciaPercentualDesc,
      'pageSize':
          ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize,
    });
  }

  Future<void> _clearClassificacaoFilter() async {
    final state = _controller.state;
    if (state.classificacao == null) {
      return;
    }
    await _controller.applyFilters(<String, Object?>{
      'agentId': state.selectedAgentId,
      'quantidadeDias': state.quantidadeDias,
      'searchTerm': state.searchTerm,
      'classificacao': null,
      'codGrupoProduto': state.codGrupoProduto,
      'codMarca': state.codMarca,
      'grupoProdutoLabel': state.grupoProdutoLabel,
      'marcaProdutoLabel': state.marcaProdutoLabel,
      'sortBy': state.sortBy.name,
      'pageSize': state.pageSize,
    });
  }

  Future<void> _applyClassificacaoFromChart(String classificacao) async {
    final state = _controller.state;
    await _controller.applyFilters(<String, Object?>{
      'agentId': state.selectedAgentId,
      'quantidadeDias': state.quantidadeDias,
      'searchTerm': state.searchTerm,
      'classificacao': classificacao,
      'codGrupoProduto': state.codGrupoProduto,
      'codMarca': state.codMarca,
      'grupoProdutoLabel': state.grupoProdutoLabel,
      'marcaProdutoLabel': state.marcaProdutoLabel,
      'sortBy': state.sortBy.name,
      'pageSize': state.pageSize,
    });
    _showFiltersAppliedSnackBar();
    _scrollToDetailsSection();
  }

  void _scrollToDetailsSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetContext = _detailsSectionKey.currentContext;
      if (targetContext == null) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        ),
      );
    });
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

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context);
    final state = _controller.state;
    final userId = _controller.boundUserId ?? '';
    final result = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => SalesProdutoTendenciaMediaMovelFiltersSheet(
        l10n: l10n,
        availableAgents: state.availableAgents,
        initialSelectedAgentId: state.selectedAgentId,
        initialQuantidadeDias: state.quantidadeDias,
        initialSearchTerm: state.searchTerm,
        initialClassificacao: state.classificacao,
        initialCodGrupoProduto: state.codGrupoProduto,
        initialCodMarca: state.codMarca,
        initialGrupoProdutoLabel: state.grupoProdutoLabel,
        initialMarcaProdutoLabel: state.marcaProdutoLabel,
        initialSortBy: state.sortBy,
        initialPageSize: state.pageSize,
        grupoProdutoLoaderFactory: _grupoProdutoLoaderFactory(userId),
        marcaProdutoLoaderFactory: _marcaProdutoLoaderFactory(userId),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    await _onFiltersChanged(result);
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

  ChartShareExportHeaderContext _exportHeaderContext(
    AppLocalizations l10n,
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    final selectedBranch = state.availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == state.selectedAgentId,
          orElse: () => null,
        );
    return buildSalesProdutoTendenciaMediaMovelChartShareExportHeaderContext(
      l10n: l10n,
      agentName: selectedBranch?.name ?? l10n.salesBranchPickerEmpty,
      quantidadeDias: state.quantidadeDias,
    );
  }

  ChartShareExportHeaderContext _detailsShareExportHeaderContext(
    AppLocalizations l10n,
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    final extraParameters = <ChartShareExportHeaderParameter>[
      ChartShareExportHeaderParameter(
        label: l10n.salesProdutoTendenciaMediaMovelFilterSortBy,
        value: produtoTendenciaMediaMovelSortLabel(l10n, state.sortBy),
      ),
      ChartShareExportHeaderParameter(
        label: l10n.salesProdutoTendenciaMediaMovelDetailsEntityLabel,
        value: state.pageResult.totalCount.toString(),
      ),
    ];
    final searchTerm = state.searchTerm.trim();
    if (searchTerm.isNotEmpty) {
      extraParameters.add(
        ChartShareExportHeaderParameter(
          label: l10n.salesProdutoTendenciaFilterSearch,
          value: searchTerm,
        ),
      );
    }
    final classificacao = state.classificacao;
    if (classificacao != null) {
      extraParameters.add(
        ChartShareExportHeaderParameter(
          label: l10n.salesProdutoTendenciaFilterClassification,
          value: produtoTendenciaMediaMovelClassificacaoLabel(
            l10n,
            classificacao,
          ),
        ),
      );
    }
    if (state.codGrupoProduto != null && state.grupoProdutoLabel != null) {
      extraParameters.add(
        ChartShareExportHeaderParameter(
          label: l10n.salesProdutoTendenciaFilterGroup,
          value: state.grupoProdutoLabel!,
        ),
      );
    }
    if (state.codMarca != null && state.marcaProdutoLabel != null) {
      extraParameters.add(
        ChartShareExportHeaderParameter(
          label: l10n.salesProdutoTendenciaFilterBrand,
          value: state.marcaProdutoLabel!,
        ),
      );
    }
    final selectedBranch = state.availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == state.selectedAgentId,
          orElse: () => null,
        );
    return buildSalesProdutoTendenciaMediaMovelChartShareExportHeaderContext(
      l10n: l10n,
      agentName: selectedBranch?.name ?? l10n.salesBranchPickerEmpty,
      quantidadeDias: state.quantidadeDias,
      extraParameters: extraParameters,
    );
  }

  void _onChartSelected(
    SalesProdutoTendenciaMediaMovelPresentationState state,
    SalesProdutoTendenciaMediaMovelChartId chartId,
    List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  ) {
    switch (chartId) {
      case SalesProdutoTendenciaMediaMovelChartId.countByClassificacao:
        _openCountChartFullscreen(state, buckets);
      case SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao:
        _openImpactChartFullscreen(state, buckets);
    }
  }

  void _openCountChartFullscreen(
    SalesProdutoTendenciaMediaMovelPresentationState state,
    List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  ) {
    final l10n = AppLocalizations.of(context);
    final fullscreenShareKey = GlobalKey();
    final shareTitle =
        l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle;
    final exportHeaderContext = _exportHeaderContext(l10n, state);
    final shareMetadata =
        buildSalesProdutoTendenciaMediaMovelCountShareMetadata(
          l10n: l10n,
          buckets: buckets,
          exportHeaderContext: exportHeaderContext,
        );
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: shareTitle,
          subtitle: l10n
              .salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle,
          chartSemanticsLabel: shareTitle,
          headerTrailing: buildChartFullscreenShareTrailing(
            context: context,
            shareKey: fullscreenShareKey,
            metadata: shareMetadata,
          ),
          chartBuilder: (fullscreenContext) {
            final fl10n = AppLocalizations.of(fullscreenContext);
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return buildSalesProdutoTendenciaMediaMovelClassificacaoBarChart(
                    context: fullscreenContext,
                    l10n: fl10n,
                    buckets: buckets,
                    countFormat: NumberFormat.decimalPattern(fl10n.localeName),
                    heightOverride: constraints.maxHeight,
                    onBucketTap: (bucket) {
                      Navigator.of(fullscreenContext).pop();
                      unawaited(
                        _applyClassificacaoFromChart(bucket.classificacao),
                      );
                    },
                    belowSubtitle: Text(
                      fl10n
                          .salesProdutoTendenciaMediaMovelSummaryByClassificacaoDrillDownHint,
                      style: Theme.of(fullscreenContext).textTheme.bodySmall
                          ?.copyWith(
                            color: Theme.of(
                              fullscreenContext,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openImpactChartFullscreen(
    SalesProdutoTendenciaMediaMovelPresentationState state,
    List<SalesProdutoTendenciaMediaMovelClassBucket> buckets,
  ) {
    final l10n = AppLocalizations.of(context);
    final fullscreenShareKey = GlobalKey();
    final shareTitle = l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle;
    final exportHeaderContext = _exportHeaderContext(l10n, state);
    final shareMetadata =
        buildSalesProdutoTendenciaMediaMovelImpactShareMetadata(
          l10n: l10n,
          buckets: buckets,
          exportHeaderContext: exportHeaderContext,
        );
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: shareTitle,
          subtitle: l10n.salesProdutoTendenciaMediaMovelSummaryByImpactSubtitle,
          chartSemanticsLabel: shareTitle,
          headerTrailing: buildChartFullscreenShareTrailing(
            context: context,
            shareKey: fullscreenShareKey,
            metadata: shareMetadata,
          ),
          chartBuilder: (fullscreenContext) {
            final ft = fullscreenContext.appTokens;
            final fl10n = AppLocalizations.of(fullscreenContext);
            final locale = Localizations.localeOf(
              fullscreenContext,
            ).toLanguageTag();
            final decimalFormat = NumberFormat.decimalPattern(fl10n.localeName);
            final colors = Theme.of(fullscreenContext).appColors;
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AppComparisonBarChart<
                    SalesProdutoTendenciaMediaMovelClassBucket
                  >(
                    items: buckets,
                    labelBuilder: (bucket) =>
                        produtoTendenciaMediaMovelClassificacaoLabel(
                          fl10n,
                          bucket.classificacao,
                        ),
                    valueBuilder: (bucket) => bucket.impacto,
                    colorBuilder: (bucket) =>
                        salesProdutoTendenciaMediaMovelClassificacaoColor(
                          colors,
                          bucket.classificacao,
                        ),
                    plotFloorAccessibilityNotice:
                        fl10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        fl10n.chartComparisonExtremeValueSpreadNotice,
                    style: salesTrendHomeLikeComparisonBarChartStyle(
                      tokens: ft,
                      l10n: fl10n,
                      yAxisFormat: NumberFormat.compact(locale: locale),
                      minPlottedValueShareOfMax: 0,
                      heightOverride: constraints.maxHeight,
                    ),
                    dataLabelBuilder: (bucket, _) =>
                        decimalFormat.format(bucket.impacto),
                    tooltipLabelBuilder: (bucket, _) =>
                        '${produtoTendenciaMediaMovelClassificacaoLabel(fl10n, bucket.classificacao)}: '
                        '${decimalFormat.format(bucket.impacto)}',
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _shareDetailsTable() async {
    final state = _controller.state;
    if (state.loading || state.pageResult.totalCount <= 0) {
      return;
    }
    if (ChartShareGuard.isInProgress(_detailsShareKey)) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = state.selectedAgentId?.trim();
    if (userId == null || agentId == null || agentId.isEmpty) {
      return;
    }

    final clientToken = await _controller.resolveClientToken(
      userId: userId,
      agentId: agentId,
    );
    if (!mounted || clientToken == null) {
      return;
    }

    final result = await _loadRowsForShare(
      userId: userId,
      agentId: agentId,
      filter: _controller.shareDetailFilter(),
      totalCount: state.pageResult.totalCount,
      clientToken: clientToken,
      cancelScope: _controller.sqlCancelScope,
    );
    if (!mounted) {
      return;
    }

    await result.fold(
      (rows) async {
        await shareChartCapture(
          context,
          buildSalesProdutoTendenciaMediaMovelDetailsShareMetadata(
            l10n: l10n,
            rows: rows,
            exportHeaderContext: _detailsShareExportHeaderContext(l10n, state),
          ).toShareRequest(_detailsShareKey),
        );
      },
      (failure) async {
        final message =
            failure is ValidationFailure &&
                failure.message == 'share_export_row_limit_exceeded'
            ? l10n.chartShareExportRowLimitExceeded(
                ChartSharePdfLimits.maxTableRows,
                state.pageResult.totalCount,
              )
            : _failureMessage(failure, l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return ChangeNotifierProvider<
      SalesProdutoTendenciaMediaMovelController
    >.value(
      value: _controller,
      child: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          cacheExtent: AppScrollTokens.chartDashboardListCacheExtent,
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
              title: l10n.salesCardProdutoTendenciaMediaMovelTitle,
              subtitle: l10n.salesProdutoTendenciaMediaMovelPageSubtitle,
            ),
            SizedBox(height: tokens.sectionSpacing),
            SalesProdutoTendenciaMediaMovelFilterSection(
              onOpenFilters: () => unawaited(_openFilters()),
              onClearClassificacaoFilter: () =>
                  unawaited(_clearClassificacaoFilter()),
            ),
            SizedBox(height: tokens.gapMd),
            SalesProdutoTendenciaMediaMovelAutoRefreshSection(
              onOptionChanged: setAutoRefreshOption,
              onRefreshNow: () => unawaited(_reload()),
              stateListenable: autoRefreshStateListenable,
            ),
            SizedBox(height: tokens.sectionSpacing),
            ListenableBuilder(
              listenable: agentQueryRetryAfterGate,
              builder: (context, _) {
                return SalesProdutoTendenciaMediaMovelBodySection(
                  detailsSectionKey: _detailsSectionKey,
                  onRetryReload: () => unawaited(_reload()),
                  onClearDetailFilters: () => unawaited(_clearDetailFilters()),
                  onOpenFilters: () => unawaited(_openFilters()),
                  onChartSelected: _onChartSelected,
                  onClassificacaoSelected: (classificacao) => unawaited(
                    _applyClassificacaoFromChart(classificacao),
                  ),
                  onClearClassificacaoFilter: () =>
                      unawaited(_clearClassificacaoFilter()),
                  retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
                  detailsShareKey: _detailsShareKey,
                  onShareDetails: () => unawaited(_shareDetailsTable()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
