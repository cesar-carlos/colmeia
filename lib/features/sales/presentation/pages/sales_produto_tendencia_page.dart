import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/chart_share_icon_button.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
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
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_auto_refresh_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_body_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_chart_nav_grid.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_classificacao_chart_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_filter_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
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
  final GlobalKey _detailsSectionKey = GlobalKey();

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

  Future<void> _applyClassificacaoFromChart(String classificacao) async {
    final state = _controller.state;
    await _controller.applyFilters(<String, Object?>{
      'agentId': state.selectedAgentId,
      'periodoAtual': state.periodoAtual,
      'periodoAnterior': state.periodoAnterior,
      'searchTerm': state.searchTerm,
      'classificacao': classificacao,
      'codGrupoProduto': state.codGrupoProduto,
      'codMarca': state.codMarca,
      'grupoProdutoLabel': state.grupoProdutoLabel,
      'marcaProdutoLabel': state.marcaProdutoLabel,
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

  Future<void> _clearClassificacaoFilter() async {
    final state = _controller.state;
    if (state.classificacao == null) {
      return;
    }
    await _controller.applyFilters(<String, Object?>{
      'agentId': state.selectedAgentId,
      'periodoAtual': state.periodoAtual,
      'periodoAnterior': state.periodoAnterior,
      'searchTerm': state.searchTerm,
      'classificacao': null,
      'codGrupoProduto': state.codGrupoProduto,
      'codMarca': state.codMarca,
      'grupoProdutoLabel': state.grupoProdutoLabel,
      'marcaProdutoLabel': state.marcaProdutoLabel,
      'pageSize': state.pageSize,
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

  void _openClassificacaoFullscreen(
    SalesProdutoTendenciaPresentationState state,
  ) {
    final l10n = AppLocalizations.of(context);
    final buckets = salesProdutoTendenciaOrderedClassBuckets(state.summaryRows);
    final fullscreenShareKey = GlobalKey();
    final shareTitle = l10n.salesProdutoTendenciaSummaryByClassificacaoTitle;
    final shareMetadata = buildSalesProdutoTendenciaClassificacaoShareMetadata(
      l10n: l10n,
      summaryRows: state.summaryRows,
      buckets: buckets,
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
            final fl10n = AppLocalizations.of(fullscreenContext);
            final countFormat = NumberFormat.decimalPattern(fl10n.localeName);
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return buildSalesProdutoTendenciaClassificacaoBarChart(
                    context: fullscreenContext,
                    l10n: fl10n,
                    buckets: buckets,
                    countFormat: countFormat,
                    heightOverride: constraints.maxHeight,
                    belowSubtitle: SalesProdutoTendenciaClassificacaoLegend(
                      l10n: fl10n,
                      buckets: buckets,
                    ),
                    onBucketTap: (bucket) {
                      Navigator.of(fullscreenContext).pop();
                      unawaited(_applyClassificacaoFromChart(bucket.classificacao));
                    },
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
      ).salesProdutoTendenciaTopGainersSubtitle,
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
      ).salesProdutoTendenciaTopLosersSubtitle,
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
                  return AppComparisonBarChart<
                    ProdutoVendidoTendenciaDeVendaRow
                  >(
                    items: items,
                    labelBuilder: (row) => row.nomeProduto,
                    valueBuilder: (row) => useAbsolutePercentForLosers
                        ? row.percentualTendencia.abs()
                        : row.percentualTendencia,
                    plotFloorAccessibilityNotice:
                        fl10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        fl10n.chartComparisonExtremeValueSpreadNotice,
                    style: salesTrendTopMoversComparisonBarChartStyle(
                      context: context,
                      tokens: ft,
                      l10n: fl10n,
                      yAxisFormat: axisFormat,
                      heightOverride: constraints.maxHeight,
                    ),
                    dataLabelBuilder: (row, _) =>
                        '${row.percentualTendencia.toStringAsFixed(1)}%',
                    tooltipLabelBuilder: (row, _) =>
                        '${row.nomeProduto} · '
                        '${row.percentualTendencia.toStringAsFixed(2)}% · '
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return ChangeNotifierProvider<SalesProdutoTendenciaController>.value(
      value: _controller,
      child: RefreshIndicator(
        onRefresh: () async {
          await _reload();
        },
        child: ListView(
          // CI release workflow uses Flutter 3.41.x; migrate to scrollCacheExtent when upgraded.
          // ignore: deprecated_member_use
          cacheExtent: 5000,
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
            SalesProdutoTendenciaFilterSection(
              onOpenFilters: () => unawaited(_openFiltersSheet()),
              onClearClassificacaoFilter: () =>
                  unawaited(_clearClassificacaoFilter()),
            ),
            SizedBox(height: tokens.gapMd),
            SalesProdutoTendenciaAutoRefreshSection(
              onOptionChanged: setAutoRefreshOption,
              onRefreshNow: () => unawaited(_reload()),
              stateListenable: autoRefreshStateListenable,
            ),
            SizedBox(height: tokens.sectionSpacing),
            ListenableBuilder(
              listenable: agentQueryRetryAfterGate,
              builder: (context, _) {
                return SalesProdutoTendenciaBodySection(
                  detailsSectionKey: _detailsSectionKey,
                  onRetryReload: () => unawaited(_reload()),
                  onClearDetailFilters: () => unawaited(_clearDetailFilters()),
                  onOpenFilters: () => unawaited(_openFiltersSheet()),
                  onChartSelected: _onChartSelected,
                  onClassificacaoSelected: (classificacao) => unawaited(
                    _applyClassificacaoFromChart(classificacao),
                  ),
                  onClearClassificacaoFilter: () =>
                      unawaited(_clearClassificacaoFilter()),
                  retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
