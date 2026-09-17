import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_chart_share_actions.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_margem_produto_page_use_case.dart';
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
import 'package:colmeia/features/sales/presentation/controllers/sales_margem_produto_controller.dart';
import 'package:colmeia/features/sales/presentation/share/sales_chart_share_export_filter.dart';
import 'package:colmeia/features/sales/presentation/share/sales_margem_produto_share.dart';
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
import 'package:colmeia/shared/widgets/reports/app_report_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesMargemProdutoPage extends StatefulWidget {
  const SalesMargemProdutoPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    required this.loadMargemProdutoPageUseCase,
    required this.loadRowsForShareUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
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
  late final SalesMargemProdutoController _controller;
  final GlobalKey _shareKey = GlobalKey();
  final ValueNotifier<SalesMargemProdutoGridSnapshot> _gridView =
      ValueNotifier<SalesMargemProdutoGridSnapshot>(
        SalesMargemProdutoGridSnapshot.initial(),
      );

  // Stable identity across builds; required for AppReportGrid column-cache hits.
  late List<AppReportColumn<MargemProdutoRow>> _columns;
  Locale? _columnsLocale;

  @override
  void initState() {
    super.initState();
    _controller = SalesMargemProdutoController(
      sessionService: widget.sessionService,
      loadSalesAvailableAgentsUseCase: widget.loadSalesAvailableAgentsUseCase,
      resolveSalesAgentClientTokenUseCase:
          widget.resolveSalesAgentClientTokenUseCase,
      loadMargemProdutoPageUseCase: widget.loadMargemProdutoPageUseCase,
      loadRowsForShareUseCase: widget.loadRowsForShareUseCase,
      relayCancelScopeBinder: widget.relayCancelScopeBinder,
    );
    _controller.addListener(_onControllerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthController>().session?.userId;
      unawaited(_bindUser(userId));
    });
    _publishGridView();
  }

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
  void dispose() {
    _controller
      ..removeListener(_onControllerTick)
      ..dispose();
    _gridView.dispose();
    super.dispose();
  }

  void _onControllerTick() {
    if (!mounted) {
      return;
    }
    _publishGridView();
    refreshAutoRefreshScheduling();
  }

  void _publishGridView() {
    _gridView.value = SalesMargemProdutoGridSnapshot(
      rows: _controller.rows,
      pageInfo: _controller.pageInfo,
      query: _controller.query,
      isLoading: _controller.isLoading && _controller.loadFailure == null,
      loadFailure: _controller.loadFailure,
    );
  }

  Future<void> _reload() => reloadWithAutoRefresh();

  @override
  SalesSessionService get salesSessionService => widget.sessionService;

  @override
  String get salesAutoRefreshCardId => SalesAutoRefreshCardIds.margemProduto;

  @override
  String? get autoRefreshSelectedAgentId => _controller.selectedAgentId;

  @override
  List<DashboardAgentOption> get autoRefreshAvailableAgents =>
      _controller.availableAgents;

  @override
  bool get autoRefreshPageLoading => _controller.isLoading;

  Future<void> _bindUser(String? userId) async {
    await _controller.bindUser(userId);
    if (!mounted) {
      return;
    }
    await _loadCatalog();
  }

  @override
  Future<void> performAutoRefreshReload() => _loadCatalog();

  Future<void> _loadCatalog({bool clearVisibleCatalog = false}) {
    return _handleCatalogLoad(
      () => _controller.loadCatalog(clearVisibleCatalog: clearVisibleCatalog),
    );
  }

  Future<void> _handleCatalogLoad(
    Future<SalesMargemProdutoLoadOutcome?> Function() load,
  ) async {
    markAutoRefreshCancelled();
    final outcome = await load();
    if (!mounted || outcome == null || outcome.isSuperseded) {
      return;
    }
    if (outcome.loadFailure != null) {
      onAgentQueryLoadFailure(outcome.loadFailure);
    }
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

  ChartShareExportHeaderContext _shareExportHeaderContext(
    AppLocalizations l10n,
  ) {
    final parameters = <ChartShareExportHeaderParameter>[];
    final normalizedSearch = SalesMargemProdutoSort.normalizeSearchTerm(
      _controller.query.searchTerm,
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
      agentName: _controller.selectedAgentName(l10n.salesBranchPickerEmpty),
      parameters: parameters,
    );
  }

  Widget _catalogHeaderTrailing(AppLocalizations l10n) {
    return AppChartHeaderTrailing(
      onOpenFullscreen: _controller.canOpenFullscreen ? _openFullscreen : null,
      openFullscreenTooltip: l10n.salesMargemProdutoFullscreenTooltip,
      onShare: _controller.canShare ? () => unawaited(_shareCatalog()) : null,
      shareProgressKey: _shareKey,
      shareEnabled: !_controller.isLoading,
    );
  }

  void _openFullscreen() {
    if (!_controller.canOpenFullscreen) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: l10n.salesCardMargemProdutoTitle,
          subtitle: l10n.salesMargemProdutoIntroSubtitle,
          filterSummary: _controller.selectedAgentName(
            l10n.salesBranchPickerEmpty,
          ),
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
                  agentId: _controller.selectedAgentId,
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
    if (!_controller.canShare) {
      return;
    }
    if (!ChartShareGuard.tryAcquire(_shareKey)) {
      return;
    }

    var transferredToCapture = false;
    try {
      final l10n = AppLocalizations.of(context);
      final exportHeaderContext = _shareExportHeaderContext(l10n);
      final totalCount = _controller.totalCount;
      final result = await _controller.loadRowsForShare();
      if (!mounted) {
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

  String _failureMessage(Object exception, AppLocalizations l10n) {
    return exception is AppFailure
        ? agentQueryFailureUserMessage(exception, l10n)
        : exception.toString();
  }

  void _onQueryChanged(AppReportQuery next) {
    unawaited(_handleCatalogLoad(() => _controller.applyQuery(next)));
  }

  void _onPageChanged(int page) {
    unawaited(
      _handleCatalogLoad(
        () => _controller.applyPaging(
          page: page,
          pageSize: _controller.pageSize,
        ),
      ),
    );
  }

  void _onPageSizeChanged(int size) {
    unawaited(
      _handleCatalogLoad(
        () => _controller.applyPaging(page: 1, pageSize: size),
      ),
    );
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
          availableAgents: _controller.availableAgents,
          initialSelectedAgentId: _controller.selectedAgentId,
          onApply: (next) => unawaited(
            _handleCatalogLoad(() => _controller.applyFilters(next)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.appTokens;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final selectedBranchName = _controller.selectedAgentName(
          l10n.salesBranchPickerEmpty,
        );

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
                ],
                footer: SalesAutoRefreshActionsRow(
                  value: autoRefreshOption,
                  onChanged: setAutoRefreshOption,
                  onRefreshNow: () => unawaited(_reload()),
                  enabled: canScheduleAutoRefresh,
                  lastUpdatedAt: autoRefreshLastUpdatedAt,
                  isPaused: autoRefreshIsPaused,
                  pauseReason: autoRefreshPauseReason,
                  l10n: l10n,
                ),
              ),
              SizedBox(height: tokens.sectionSpacing),
              Expanded(
                child: _SalesMargemProdutoReportSurface(
                  controller: _controller,
                  columns: _columns,
                  headerTrailing: _catalogHeaderTrailing(l10n),
                  onQueryChanged: _onQueryChanged,
                  onPageChanged: _onPageChanged,
                  onPageSizeChanged: _onPageSizeChanged,
                  onRefresh: _loadCatalog,
                  retryCountdownLabel: agentQueryRetryCountdownLabel(l10n),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SalesMargemProdutoReportSurface extends StatelessWidget {
  const _SalesMargemProdutoReportSurface({
    required this.controller,
    required this.columns,
    required this.headerTrailing,
    required this.onQueryChanged,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    required this.onRefresh,
    this.retryCountdownLabel,
  });

  final SalesMargemProdutoController controller;
  final List<AppReportColumn<MargemProdutoRow>> columns;
  final Widget headerTrailing;
  final ValueChanged<AppReportQuery> onQueryChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final Future<void> Function() onRefresh;
  final String? retryCountdownLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loadFailure = controller.loadFailure;

    if (controller.selectedAgentId == null) {
      return AppInlineErrorPanel(
        tone: AppInlinePanelTone.informational,
        title: l10n.salesBranchRequiredTitle,
        message: l10n.salesBranchRequiredMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridHeight = resolveSalesMargemProdutoGridHeight(
          maxHeight: constraints.maxHeight,
          chromeHeight: kSalesMargemProdutoPageChromeHeight,
          maxGridHeight: kSalesMargemProdutoPageGridMaxHeight,
        );
        return AppReportViewer<MargemProdutoRow>(
          headerTrailing: headerTrailing,
          columns: columns,
          rows: controller.rows,
          pageInfo: controller.pageInfo,
          query: controller.query,
          events: AppReportEvents<MargemProdutoRow>(
            onQueryChanged: onQueryChanged,
            onPageChanged: onPageChanged,
            onPageSizeChanged: onPageSizeChanged,
            onRefresh: onRefresh,
          ),
          style: salesMargemProdutoReportViewerStyle(
            entityLabel: l10n.salesMargemProdutoEntityLabel,
            gridHeight: gridHeight,
          ),
          isLoading: controller.isLoading && loadFailure == null,
          loadErrorPanel: loadFailure == null
              ? null
              : AgentQueryErrorPanelFactory.fromFailure(
                  loadFailure,
                  l10n,
                  onRetry: () => unawaited(onRefresh()),
                  retryCountdownLabel: retryCountdownLabel,
                  supportContext: AgentQueryFailureSupportContext.environment(
                    extra: <String, String>{
                      'agentId': ?controller.selectedAgentId,
                      'screen': 'sales_margem_produto',
                    },
                  ),
                ),
          onRetry: () => unawaited(onRefresh()),
          emptyMessage:
              SalesMargemProdutoSort.normalizeSearchTerm(
                    controller.query.searchTerm,
                  ) ==
                  null
              ? l10n.salesMargemProdutoEmpty
              : l10n.salesMargemProdutoEmptySearch,
          searchHintText: l10n.salesMargemProdutoSearchHint,
        );
      },
    );
  }
}
