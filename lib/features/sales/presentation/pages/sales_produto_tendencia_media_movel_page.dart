import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
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
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_support_context.dart';
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
import 'package:colmeia/features/sales/presentation/share/sales_produto_tendencia_media_movel_share.dart';
import 'package:colmeia/features/sales/presentation/state/sales_produto_tendencia_media_movel_presentation_state.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_chart_nav_grid.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_classificacao_labels.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_details_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_produto_tendencia_media_movel_summary_section.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_trend_comparison_bar_chart_style.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/agent_query_error_panel.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_header_trailing.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
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
    if (mounted) {
      setState(() {});
    }
  }

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

  bool _isChartReady(
    SalesProdutoTendenciaMediaMovelPresentationState state,
    SalesProdutoTendenciaMediaMovelChartId chartId,
  ) {
    if (state.summaryRows.isEmpty) {
      return false;
    }
    return switch (chartId) {
      SalesProdutoTendenciaMediaMovelChartId.countByClassificacao =>
        state.summaryRows.isNotEmpty,
      SalesProdutoTendenciaMediaMovelChartId.impactByClassificacao =>
        state.summaryRows.isNotEmpty,
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

  String _detailsShareFilterSummary(
    AppLocalizations l10n,
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    final parts = <String>[
      l10n.salesProdutoTendenciaMediaMovelFilterQuantidadeDiasValue(
        state.quantidadeDias,
      ),
      l10n.salesProdutoTendenciaMediaMovelDetailsSortedBy(
        produtoTendenciaMediaMovelSortLabel(l10n, state.sortBy),
      ),
      '${state.pageResult.totalCount} ${l10n.salesProdutoTendenciaMediaMovelDetailsEntityLabel}',
    ];
    if (state.searchTerm.trim().isNotEmpty) {
      parts.add(state.searchTerm.trim());
    }
    if (state.classificacao != null) {
      parts.add(
        produtoTendenciaMediaMovelClassificacaoLabel(l10n, state.classificacao!),
      );
    }
    if (state.codGrupoProduto != null && state.grupoProdutoLabel != null) {
      parts.add(state.grupoProdutoLabel!);
    }
    if (state.codMarca != null && state.marcaProdutoLabel != null) {
      parts.add(state.marcaProdutoLabel!);
    }
    return parts.join(' · ');
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
    final tokens = context.appTokens;
    final fullscreenShareKey = GlobalKey();
    final shareTitle =
        l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoTitle;
    final shareMetadata = buildSalesProdutoTendenciaMediaMovelCountShareMetadata(
      l10n: l10n,
      buckets: buckets,
      tokens: tokens,
    );
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: shareTitle,
          subtitle:
              l10n.salesProdutoTendenciaMediaMovelSummaryByClassificacaoSubtitle,
          chartSemanticsLabel: shareTitle,
          headerTrailing: buildChartFullscreenShareTrailing(
            context: context,
            shareKey: fullscreenShareKey,
            metadata: shareMetadata,
          ),
          chartBuilder: (fullscreenContext) {
            final ft = fullscreenContext.appTokens;
            final fl10n = AppLocalizations.of(fullscreenContext);
            final locale =
                Localizations.localeOf(fullscreenContext).toLanguageTag();
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AppComparisonBarChart<
                      SalesProdutoTendenciaMediaMovelClassBucket>(
                    items: buckets,
                    labelBuilder: (bucket) =>
                        produtoTendenciaMediaMovelClassificacaoLabel(
                      fl10n,
                      bucket.classificacao,
                    ),
                    valueBuilder: (bucket) => bucket.count,
                    plotFloorAccessibilityNotice:
                        fl10n.chartComparisonPlotFloorNotice,
                    extremeSpreadAccessibilityNotice:
                        fl10n.chartComparisonExtremeValueSpreadNotice,
                    style: salesTrendHomeLikeComparisonBarChartStyle(
                      tokens: ft,
                      l10n: fl10n,
                      yAxisFormat: NumberFormat.compact(locale: locale),
                      heightOverride: constraints.maxHeight,
                    ),
                    dataLabelBuilder: (bucket, _) => '${bucket.count}',
                    tooltipLabelBuilder: (bucket, _) =>
                        '${produtoTendenciaMediaMovelClassificacaoLabel(fl10n, bucket.classificacao)}: '
                        '${bucket.count}',
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
    final tokens = context.appTokens;
    final fullscreenShareKey = GlobalKey();
    final shareTitle = l10n.salesProdutoTendenciaMediaMovelSummaryByImpactTitle;
    final shareMetadata =
        buildSalesProdutoTendenciaMediaMovelImpactShareMetadata(
      l10n: l10n,
      buckets: buckets,
      tokens: tokens,
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
            final locale =
                Localizations.localeOf(fullscreenContext).toLanguageTag();
            final decimalFormat = NumberFormat.decimalPattern(fl10n.localeName);
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AppComparisonBarChart<
                      SalesProdutoTendenciaMediaMovelClassBucket>(
                    items: buckets,
                    labelBuilder: (bucket) =>
                        produtoTendenciaMediaMovelClassificacaoLabel(
                      fl10n,
                      bucket.classificacao,
                    ),
                    valueBuilder: (bucket) => bucket.impacto,
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
    if (!ChartShareGuard.tryAcquire(_detailsShareKey)) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    try {
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

      result.fold(
        (rows) {
          ChartShareGuard.release(_detailsShareKey);
          context.shareChartFromRequest(
            buildSalesProdutoTendenciaMediaMovelDetailsShareMetadata(
              l10n: l10n,
              rows: rows,
              filterSummary: _detailsShareFilterSummary(l10n, state),
            ).toShareRequest(_detailsShareKey),
          );
        },
        (failure) {
          ChartShareGuard.release(_detailsShareKey);
          final message =
              failure is ValidationFailure &&
                  failure.message == 'share_export_row_limit_exceeded'
              ? l10n.salesProdutoTendenciaMediaMovelShareRowLimitExceeded(
                  LoadMediaMovelRowsForShareUseCase.maxExportRowCount,
                  state.pageResult.totalCount,
                )
              : _failureMessage(failure, l10n);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } finally {
      ChartShareGuard.release(_detailsShareKey);
    }
  }

  List<String> _activeFilterChipLabels(
    AppLocalizations l10n,
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    final labels = <String>[];
    final trimmedSearch = state.searchTerm.trim();
    if (trimmedSearch.isNotEmpty) {
      labels.add('${l10n.salesProdutoTendenciaFilterSearch}: $trimmedSearch');
    }
    if (state.classificacao != null) {
      labels.add(
        '${l10n.salesProdutoTendenciaFilterClassification}: '
        '${produtoTendenciaMediaMovelClassificacaoLabel(l10n, state.classificacao!)}',
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

  int _activeFilterCount(
    SalesProdutoTendenciaMediaMovelPresentationState state,
  ) {
    var count = _activeFilterChipLabels(AppLocalizations.of(context), state)
        .length;
    if (state.sortBy !=
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy
            .tendenciaPercentualDesc) {
      count++;
    }
    if (state.pageSize !=
        ProdutoVendidoTendenciaDeVendaMediaMovelFilter.defaultPageSize) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final selectedBranch = state.availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == state.selectedAgentId,
          orElse: () => null,
        );
    final summary = buildSalesProdutoTendenciaMediaMovelSummary(state.summaryRows);
    final hasSummary = state.summaryRows.isNotEmpty;
    final hasActiveDetailFilters = _activeFilterCount(state) > 0;
    final totalPages = state.pageResult.totalCount == 0
        ? 0
        : (state.pageResult.totalCount / state.pageSize).ceil();
    final rangeStart = state.pageResult.totalCount == 0
        ? 0
        : ((state.page - 1) * state.pageSize) + 1;
    final rangeEnd = state.pageResult.totalCount == 0
        ? 0
        : math.min(state.page * state.pageSize, state.pageResult.totalCount);
    final activeFilterChipLabels = _activeFilterChipLabels(l10n, state);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
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
              title: l10n.salesCardProdutoTendenciaMediaMovelTitle,
              subtitle: l10n.salesProdutoTendenciaMediaMovelPageSubtitle,
            ),
                  SizedBox(height: tokens.sectionSpacing),
                  // Branch is inline here (not only in the filters sheet) so users
                  // can switch agents without opening filters; period trend keeps
                  // branch selection inside the sheet only.
                  SalesBranchPickerControl(
                    l10n: l10n,
                    availableBranches: state.availableAgents,
                    selectedBranchId: state.selectedAgentId,
                    onSelectionChanged: (agentId) {
                      unawaited(_controller.changeAgent(agentId));
                    },
                  ),
                  SizedBox(height: tokens.gapMd),
                  SalesCardFilterTrigger(
                    enabled: !state.loading,
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
                              state.quantidadeDias,
                            ),
                      ),
                      SalesCardFilterSummaryItem(
                        label: l10n.salesProdutoTendenciaMediaMovelFilterSortBy,
                        value: produtoTendenciaMediaMovelSortLabel(
                          l10n,
                          state.sortBy,
                        ),
                      ),
                      SalesCardFilterSummaryItem(
                        label: l10n.reportFiltersTitle,
                        value: l10n
                            .salesProdutoTendenciaMediaMovelActiveFiltersSummary(
                              _activeFilterCount(state),
                            ),
                      ),
                    ],
                    onTap: _openFilters,
                    buttonSemanticsLabel: l10n.reportFiltersTitleWithContext(
                      l10n.salesCardProdutoTendenciaMediaMovelTitle,
                    ),
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
                  if (state.selectedAgentId == null ||
                      state.selectedAgentId!.trim().isEmpty) ...<Widget>[
                    SizedBox(height: tokens.sectionSpacing),
                    AppInlineErrorPanel(
                      tone: AppInlinePanelTone.informational,
                      title: l10n.salesBranchRequiredTitle,
                      message:
                          l10n.salesProdutoTendenciaMediaMovelSelectAgentHint,
                    ),
                  ] else if (state.loadFailure != null) ...<Widget>[
                    SizedBox(height: tokens.sectionSpacing),
                    AgentQueryErrorPanel.fromFailure(
                      state.loadFailure!,
                      l10n,
                      onRetry: _reload,
                      retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
                      supportContext: AgentQueryFailureSupportContext.environment(
                        extra: <String, String>{
                          'agentId': ?state.selectedAgentId,
                          'screen': 'sales_produto_tendencia_media_movel',
                        },
                      ),
                    ),
                  ] else if (state.authenticationFailed) ...<Widget>[
                    SizedBox(height: tokens.sectionSpacing),
                    AppInlineErrorPanel(
                      title: l10n.salesProdutoTendenciaMediaMovelDetailsTitle,
                      message: l10n.agentSqlErrorAuthenticationFailed,
                      onRetry: _reload,
                    ),
                  ] else ...<Widget>[
                    SizedBox(height: tokens.sectionSpacing),
                    SalesProdutoTendenciaMediaMovelSummarySection(
                      l10n: l10n,
                      summary: summary,
                      loading: state.loading,
                      hasSummaryRows: hasSummary,
                      hasActiveDetailFilters: hasActiveDetailFilters,
                      onClearFilters: () => unawaited(_clearDetailFilters()),
                      onOpenFilters: _openFilters,
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    SalesProdutoTendenciaMediaMovelChartNavGrid(
                      l10n: l10n,
                      loading: state.loading,
                      sectionTitle: l10n.salesProdutoTendenciaChartsSectionTitle,
                      isChartReady: (chartId) => _isChartReady(state, chartId),
                      onChartSelected: (chartId) => _onChartSelected(
                        state,
                        chartId,
                        summary.buckets,
                      ),
                    ),
                    SizedBox(height: tokens.sectionSpacing),
                    SalesProdutoTendenciaMediaMovelDetailsSection(
                      l10n: l10n,
                      loading: state.loading,
                      rows: state.pageResult.items,
                      totalCount: state.pageResult.totalCount,
                      pageSize: state.pageSize,
                      currentPage: state.page,
                      totalPages: totalPages,
                      rangeStart: rangeStart,
                      rangeEnd: rangeEnd,
                      sortBy: state.sortBy,
                      hasActiveDetailFilters: hasActiveDetailFilters,
                      onClearFilters: () => unawaited(_clearDetailFilters()),
                      onOpenFilters: _openFilters,
                      headerTrailing: AppChartHeaderTrailing(
                        shareProgressKey: _detailsShareKey,
                        shareEnabled:
                            !state.loading && state.pageResult.totalCount > 0,
                        onShare:
                            state.loading || state.pageResult.totalCount <= 0
                            ? null
                            : () => unawaited(_shareDetailsTable()),
                      ),
                      onPageSelected: (page) {
                        unawaited(_controller.selectPage(page));
                      },
                      onNext: state.page < totalPages
                          ? () =>
                                unawaited(_controller.selectPage(state.page + 1))
                          : null,
                      onPrevious: state.page > 1
                          ? () =>
                                unawaited(_controller.selectPage(state.page - 1))
                          : null,
                      onPageSizeChanged: (value) {
                        unawaited(_controller.changePageSize(value));
                      },
                    ),
                  ],
        ],
      ),
    );
  }
}
