import 'dart:async';
import 'dart:math' as math;

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/router/chart_share_icon_button.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/refresh/auto_refresh_state_mixin.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_retry_after_host.dart';
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_chart_failure_placeholder_content.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_single_agent_auto_refresh_mixin.dart';
import 'package:colmeia/features/sales/presentation/sales_monthly_pnl_chart_keys.dart';
import 'package:colmeia/features/sales/presentation/share/sales_monthly_pnl_share.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/utils/sales_anchor_month_support.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_anchor_month_filters_context.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_auto_refresh_actions_row.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_branch_anchor_month_filters_sheet.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_card_filter_trigger.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_daily_totals_chart_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_monthly_pnl_bar_chart_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const double _kSalesMonthlyPnlMinChartWidth = 560;
const double _kSalesMonthlyPnlMonthSlotWidth = 72;
const double _kSalesMonthlyPnlChartHorizontalPadding = 24;

String _formatChartMonthShortLabel(
  SalesMonthlyPnlPoint point,
  String localeTag,
) {
  return DateFormat(
    'MMM/yy',
    localeTag,
  ).format(DateTime(point.year, point.month));
}

String _formatChartMonthLongLabel(
  SalesMonthlyPnlPoint point,
  String localeTag,
) {
  return DateFormat.yMMM(localeTag).format(DateTime(point.year, point.month));
}

String _tooltipSeriesLabel(
  AppLocalizations l10n,
  int seriesIndex,
) {
  return switch (seriesIndex) {
    1 => l10n.salesMonthlyPnlSeriesProfitLabel,
    2 => l10n.salesMonthlyPnlSeriesCostLabel,
    _ => l10n.salesMonthlyPnlSeriesSalesLabel,
  };
}

double _tooltipSeriesValue(
  SalesMonthlyPnlPoint point,
  int seriesIndex,
) {
  return switch (seriesIndex) {
    1 => point.lucro,
    2 => point.custoMercadoria,
    _ => point.venda,
  };
}

double _resolveSalesMonthlyPnlChartWidth({
  required double availableWidth,
  required int pointCount,
}) {
  final contentWidth =
      (pointCount * _kSalesMonthlyPnlMonthSlotWidth) +
      _kSalesMonthlyPnlChartHorizontalPadding;
  return math.max(
    availableWidth,
    math.max(_kSalesMonthlyPnlMinChartWidth, contentWidth),
  );
}

class SalesMonthlyPnlPage extends StatefulWidget {
  const SalesMonthlyPnlPage({
    required this.sessionService,
    required this.loadSalesAvailableAgentsUseCase,
    required this.loadSalesMonthlyPnlLinesUseCase,
    required this.loadSalesDailyTotalsUseCase,
    required this.resolveSalesAgentClientTokenUseCase,
    this.relayCancelScopeBinder,
    super.key,
  });

  final SalesSessionService sessionService;
  final LoadAvailableAgentsForSales loadSalesAvailableAgentsUseCase;
  final LoadSalesMonthlyPnlLinesUseCase loadSalesMonthlyPnlLinesUseCase;
  final LoadSalesDailyTotalsUseCase loadSalesDailyTotalsUseCase;
  final ResolveSalesAgentClientTokenUseCase resolveSalesAgentClientTokenUseCase;
  final AgentQueriesRelayCancelScopeBinder? relayCancelScopeBinder;

  @override
  State<SalesMonthlyPnlPage> createState() => _SalesMonthlyPnlPageState();
}

class _SalesMonthlyPnlPageState extends State<SalesMonthlyPnlPage>
    with
        AutoRefreshStateMixin<SalesMonthlyPnlPage>,
        SalesSingleAgentAutoRefreshMixin<SalesMonthlyPnlPage>,
        SalesCardAutoRefreshBinding<SalesMonthlyPnlPage>,
        AgentQueryRetryAfterHost<SalesMonthlyPnlPage> {
  late final SalesSessionService _sessionService;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  late final LoadSalesMonthlyPnlLinesUseCase _loadPnlLines;
  late final LoadSalesDailyTotalsUseCase _loadDailyTotals;
  late final ResolveSalesAgentClientTokenUseCase _resolveClientTokenUseCase;

  String? _selectedAgentId;
  List<DashboardAgentOption> _availableAgents = <DashboardAgentOption>[];
  late DashboardYearMonth _anchorYearMonth;
  DashboardDateRange? _dailyTotalsDateRange;
  String? _cachedClientTokenUserId;
  String? _cachedClientTokenAgentId;
  String? _cachedClientToken;

  List<SalesMonthlyPnlPoint> _points = const <SalesMonthlyPnlPoint>[];
  List<DailySalesTrendPoint> _dailyPoints =
      const <DailySalesTrendPoint>[];
  bool _loading = false;
  bool _chartLoadFailed = false;
  AppFailure? _chartLoadFailure;
  String? _chartLoadFailureMessage;
  bool _dailyChartLoadFailed = false;
  AppFailure? _dailyChartLoadFailure;
  String? _dailyChartLoadFailureMessage;
  int _chartLoadGeneration = 0;
  AgentQueriesCancelScope? _sqlCancelScope;

  @override
  void dispose() {
    _sqlCancelScope?.cancelAll();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService;
    _loadAgentsUseCase = widget.loadSalesAvailableAgentsUseCase;
    _loadPnlLines = widget.loadSalesMonthlyPnlLinesUseCase;
    _loadDailyTotals = widget.loadSalesDailyTotalsUseCase;
    _resolveClientTokenUseCase = widget.resolveSalesAgentClientTokenUseCase;
    _selectedAgentId = _sessionService.selectedAgentId;
    _anchorYearMonth =
        _sessionService.restoreSalesChartReferenceMonth() ??
        DashboardYearMonth.fromDate(DateTime.now());
    _dailyTotalsDateRange =
        _sessionService.restoreSalesDailyTotalsUseCustomRange()
        ? _sessionService.restoreSalesDailyTotalsDateRange()
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAgents());
    });
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

  Future<void> _reload({bool force = false}) =>
      reloadWithAutoRefresh(force: force);

  @override
  SalesSessionService get salesSessionService => _sessionService;

  @override
  String get salesAutoRefreshCardId => SalesAutoRefreshCardIds.monthlyPnl;

  @override
  String? get autoRefreshSelectedAgentId => _selectedAgentId;

  @override
  List<DashboardAgentOption> get autoRefreshAvailableAgents => _availableAgents;

  @override
  bool get autoRefreshPageLoading => _loading;

  @override
  Future<void> performAutoRefreshReload() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    final agentId = _selectedAgentId;
    final anchor = _anchorYearMonth;
    final generation = ++_chartLoadGeneration;
    _sqlCancelScope?.cancelAll();
    final sqlScope = AgentQueriesCancelScope();
    _sqlCancelScope = sqlScope;
    widget.relayCancelScopeBinder?.call(sqlScope);
    markAutoRefreshCancelled();

    setState(() {
      _loading = true;
      _chartLoadFailed = false;
      _chartLoadFailure = null;
      _chartLoadFailureMessage = null;
      _dailyChartLoadFailed = false;
      _dailyChartLoadFailure = null;
      _dailyChartLoadFailureMessage = null;
    });

    if (userId == null || agentId == null || agentId.trim().isEmpty) {
      if (!mounted || generation != _chartLoadGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _points = const <SalesMonthlyPnlPoint>[];
        _chartLoadFailed = false;
        _chartLoadFailureMessage = null;
        _dailyPoints = const <DailySalesTrendPoint>[];
        _dailyChartLoadFailed = false;
      _dailyChartLoadFailure = null;
        _dailyChartLoadFailureMessage = null;
      });
      return;
    }

    final trimmed = agentId.trim();
    final clientToken = await _resolveClientToken(
      userId: userId,
      agentId: trimmed,
    );
    if (!mounted || generation != _chartLoadGeneration) {
      return;
    }
    if (clientToken == null) {
      final authMsg = AppLocalizations.of(
        context,
      ).agentSqlErrorAuthenticationFailed;
      setState(() {
        _loading = false;
        _points = const <SalesMonthlyPnlPoint>[];
        _chartLoadFailed = true;
        _chartLoadFailureMessage = authMsg;
        _dailyPoints = const <DailySalesTrendPoint>[];
        _dailyChartLoadFailed = true;
        _dailyChartLoadFailureMessage = authMsg;
      });
      markAutoRefreshCancelled();
      return;
    }

    final futures = await Future.wait(<Future<Object>>[
      _loadPnlLines(
        userId: userId,
        agentId: trimmed,
        anchor: anchor,
        clientToken: clientToken,
        cancelScope: sqlScope,
      ),
      _loadDailyTotals(
        userId: userId,
        agentId: trimmed,
        anchor: anchor,
        dailySaleDateRange: _dailyTotalsDateRange,
        clientToken: clientToken,
        cancelScope: sqlScope,
      ),
    ]);

    if (!mounted || generation != _chartLoadGeneration) {
      return;
    }
    final bundle = futures[0] as SalesMonthlyPnlLinesLoadResult;
    final dailyBundle = futures[1] as SalesDailyTotalsLoadResult;
    setState(() {
      _points = bundle.points;
      _chartLoadFailed = bundle.loadFailed;
      _chartLoadFailure = bundle.loadFailure;
      _chartLoadFailureMessage = bundle.loadFailure == null
          ? null
          : agentQueryFailureUserMessage(
              bundle.loadFailure!,
              AppLocalizations.of(context),
            );
      _dailyPoints = dailyBundle.points;
      _dailyChartLoadFailed = dailyBundle.loadFailed;
      _dailyChartLoadFailure = dailyBundle.loadFailure;
      _dailyChartLoadFailureMessage = dailyBundle.loadFailure == null
          ? null
          : agentQueryFailureUserMessage(
              dailyBundle.loadFailure!,
              AppLocalizations.of(context),
            );
      _loading = false;
    });
    onAgentQueryLoadFailure(bundle.loadFailure ?? dailyBundle.loadFailure);
    if (bundle.loadFailed || dailyBundle.loadFailed) {
      markAutoRefreshFailure();
      return;
    }
    markAutoRefreshSuccess();
  }

  void _onFiltersChanged(Map<String, Object?> next) {
    final nextAgentId = (next['agentId'] as String?)?.trim();
    final normalizedAgentId = nextAgentId == null || nextAgentId.isEmpty
        ? null
        : nextAgentId;
    final anchor = next['anchorYearMonth'] as DashboardYearMonth?;
    final dailyRange = next['dailyTotalsDateRange'] as DashboardDateRange?;

    setState(() {
      _selectedAgentId = normalizedAgentId;
      if (anchor != null) {
        _anchorYearMonth = anchor;
      }
      _dailyTotalsDateRange = dailyRange;
    });
    unawaited(_sessionService.setSelectedAgentId(normalizedAgentId));
    if (anchor != null) {
      unawaited(_sessionService.persistSalesChartReferenceMonth(anchor));
    }
    unawaited(
      _sessionService.persistSalesDailyTotalsDateRange(
        useCustomRange: dailyRange != null,
        range: dailyRange,
      ),
    );
    unawaited(_reload(force: true));
  }

  String _dailyTotalsPeriodSummaryLine(AppLocalizations l10n) {
    final range = _dailyTotalsDateRange;
    if (range == null) {
      return formatSalesAnchorMonthLabel(context, _anchorYearMonth);
    }
    return l10n.salesDailyTotalsFilterSummaryCustomRangeValue(
      AppBrFormatters.shortDate(range.startInclusive),
      AppBrFormatters.shortDate(range.endInclusive),
    );
  }

  String _monthlyPnlFullscreenFilterSummary(AppLocalizations l10n) {
    final selectedBranch = _availableAgents
        .cast<DashboardAgentOption?>()
        .firstWhere(
          (agent) => agent?.agentId == _selectedAgentId,
          orElse: () => null,
        );
    final branchName = selectedBranch?.name ?? l10n.salesBranchPickerEmpty;
    final anchorValue = formatSalesAnchorMonthLabel(context, _anchorYearMonth);
    final base = l10n.salesMonthlyPnlFullscreenFilterSummary(
      l10n.salesBranchFilterLabel,
      branchName,
      l10n.salesMonthlyPnlFilterAnchorMonth,
      anchorValue,
    );
    final range = _dailyTotalsDateRange;
    if (range == null) {
      return base;
    }
    final suffix = l10n.salesMonthlyPnlFullscreenDailyTotalsPeriodSuffix(
      AppBrFormatters.shortDate(range.startInclusive),
      AppBrFormatters.shortDate(range.endInclusive),
    );
    return '$base $suffix';
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
        return SalesBranchAnchorMonthFiltersSheet(
          l10n: AppLocalizations.of(context),
          filtersContext: SalesAnchorMonthFiltersContext.monthlyPnl,
          availableAgents: _availableAgents,
          initialSelectedAgentId: _selectedAgentId,
          initialAnchorYearMonth: _anchorYearMonth,
          initialDailyTotalsUseCustomRange: _dailyTotalsDateRange != null,
          initialDailyTotalsDateRange: _dailyTotalsDateRange,
          onApply: _onFiltersChanged,
        );
      },
    );
  }

  void _openChartFullscreen() {
    final pointsSnapshot = List<SalesMonthlyPnlPoint>.of(
      _points,
      growable: false,
    );
    final isLoadingSnapshot = _loading && _selectedAgentId != null;
    final loadFailedSnapshot = _chartLoadFailed;
    final loadFailureMessageSnapshot = _chartLoadFailureMessage;
    final pageL10n = AppLocalizations.of(context);
    final fullscreenShareKey = GlobalKey();
    final shareTitle = pageL10n.salesMonthlyPnlChartTitle;
    unawaited(
      context.pushChartFullscreen<void>(
        extra: AppChartFullscreenRouteExtra(
          title: shareTitle,
          subtitle: pageL10n.salesMonthlyPnlChartSubtitle,
          filterSummary: _monthlyPnlFullscreenFilterSummary(pageL10n),
          chartSemanticsLabel: pageL10n.salesMonthlyPnlChartSemantics,
          headerTrailing: buildChartFullscreenShareTrailing(
            context: context,
            shareKey: fullscreenShareKey,
            metadata: buildSalesMonthlyPnlLineChartShareMetadata(
              l10n: pageL10n,
              points: pointsSnapshot,
            ),
          ),
          chartBuilder: (fullscreenContext) {
            final l10n = AppLocalizations.of(fullscreenContext);
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _SalesMonthlyPnlLineChart(
                  l10n: l10n,
                  points: pointsSnapshot,
                  loadFailed: loadFailedSnapshot,
                  loadFailureMessage: loadFailureMessageSnapshot,
                  isLoading: isLoadingSnapshot,
                  useChartShell: false,
                  chartHeightOverride: constraints.maxHeight,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openBarChartFullscreen() {
    unawaited(
      pushSalesMonthlyPnlBarChartFullscreen(
        context: context,
        points: List<SalesMonthlyPnlPoint>.of(_points, growable: false),
        initialSession: _sessionService.restoreMonthlyPnlBarChartPreferences(),
        isLoading: _loading && _selectedAgentId != null,
        loadFailed: _chartLoadFailed,
        loadFailureMessage: _chartLoadFailureMessage,
        filterSummary: _monthlyPnlFullscreenFilterSummary(
          AppLocalizations.of(context),
        ),
      ),
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
    final anchorLabel = formatSalesAnchorMonthLabel(context, _anchorYearMonth);

    return SingleChildScrollView(
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
            title: l10n.salesCardMonthlyPnlTitle,
            subtitle: l10n.salesMonthlyPnlPageSubtitle,
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
                label: l10n.salesMonthlyPnlFilterAnchorMonth,
                value: anchorLabel,
              ),
              SalesCardFilterSummaryItem(
                label: l10n.salesDailyTotalsFilterSummaryLabel,
                value: _dailyTotalsPeriodSummaryLine(l10n),
              ),
            ],
            enabled: !_loading,
          ),
          SizedBox(height: tokens.gapMd),
          SalesAutoRefreshActionsRow(
            value: autoRefreshOption,
            onChanged: setAutoRefreshOption,
            onRefreshNow: () => unawaited(_reload()),
            enabled: canScheduleAutoRefresh,
            refreshNowEnabled:
                canScheduleAutoRefresh && !isAgentQueryRetryCooldown,
            lastUpdatedAt: autoRefreshLastUpdatedAt,
            isPaused: autoRefreshIsPaused || isAgentQueryRetryCooldown,
            pauseReason: isAgentQueryRetryCooldown
                ? null
                : autoRefreshPauseReason,
            l10n: l10n,
          ),
          SizedBox(height: tokens.sectionSpacing),
          if (_selectedAgentId == null)
            AppInlineErrorPanel(
              tone: AppInlinePanelTone.informational,
              title: l10n.salesBranchRequiredTitle,
              message: l10n.salesBranchRequiredMessage,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RepaintBoundary(
                  child: _SalesMonthlyPnlLineChart(
                    l10n: l10n,
                    points: _points,
                    loadFailed: _chartLoadFailed,
                    loadFailure: _chartLoadFailure,
                    loadFailureMessage: _chartLoadFailureMessage,
                    isLoading: _loading && _selectedAgentId != null,
                    onOpenFullscreen: _openChartFullscreen,
                    onRequestShare: (context, request) =>
                        context.shareChartFromRequest(request),
                  ),
                ),
                SizedBox(height: tokens.sectionSpacing),
                RepaintBoundary(
                  child: SalesMonthlyPnlBarChartCard(
                    l10n: l10n,
                    points: _points,
                    loadFailed: _chartLoadFailed,
                    loadFailure: _chartLoadFailure,
                    loadFailureMessage: _chartLoadFailureMessage,
                    isLoading: _loading && _selectedAgentId != null,
                    initialSession: _sessionService
                        .restoreMonthlyPnlBarChartPreferences(),
                    persistSession:
                        _sessionService.persistMonthlyPnlBarChartPreferences,
                    onOpenFullscreen: _openBarChartFullscreen,
                    onRequestShare: (context, request) =>
                        context.shareChartFromRequest(request),
                  ),
                ),
                SizedBox(height: tokens.sectionSpacing),
                SalesDailyTotalsChartCard(
                  l10n: l10n,
                  points: _dailyPoints,
                  loadFailed: _dailyChartLoadFailed,
                  loadFailure: _dailyChartLoadFailure,
                  loadFailureMessage: _dailyChartLoadFailureMessage,
                  isLoading: _loading && _selectedAgentId != null,
                  dailySaleDateRange: _dailyTotalsDateRange,
                  onRequestFullscreen: (context, request) =>
                      context.pushChartFullscreenFromRequest(request),
                  onRequestShare: (context, request) =>
                      context.shareChartFromRequest(request),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SalesMonthlyPnlLineChart extends StatefulWidget {
  const _SalesMonthlyPnlLineChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    this.loadFailure,
    this.loadFailureMessage,
    this.onOpenFullscreen,
    this.onRequestShare,
    this.useChartShell = true,
    this.chartHeightOverride,
  });

  final AppLocalizations l10n;
  final List<SalesMonthlyPnlPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;
  final VoidCallback? onOpenFullscreen;
  final AppChartShareRequestCallback? onRequestShare;
  final bool useChartShell;
  final double? chartHeightOverride;

  @override
  State<_SalesMonthlyPnlLineChart> createState() =>
      _SalesMonthlyPnlLineChartState();
}

class _SalesMonthlyPnlLineChartState extends State<_SalesMonthlyPnlLineChart> {
  final GlobalKey _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final localeTag = l10n.localeName;
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: AppChartPreset.standard,
    );
    final yAxisFormat = AppBrFormatters.compactCurrencyFormatForLocale(
      localeTag,
    );
    final loadFailed = widget.loadFailed;
    final loadFailure = widget.loadFailure;
    final loadFailureMessage = widget.loadFailureMessage;
    final isLoading = widget.isLoading;
    final points = widget.points;
    final onOpenFullscreen = widget.onOpenFullscreen;
    final useChartShell = widget.useChartShell;
    final chartHeightOverride = widget.chartHeightOverride;

    final emptyMessage = loadFailed
        ? (loadFailureMessage ?? l10n.salesMonthlyPnlLoadFailed)
        : l10n.salesMonthlyPnlEmpty;
    final semanticsLabel = l10n.salesMonthlyPnlChartSemantics;
    final resolvedHeight = chartHeightOverride ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);
    final animationDuration = resolveChartAnimationDurationMs(
      context: context,
      styleDuration: const Duration(milliseconds: 350),
      defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
    );

    final chartBody = isLoading
        ? buildChartLoadingState(
            context: context,
            height: resolvedHeight,
            indicatorColor: chartTheme.primaryColor,
            label: l10n.overviewComparisonChartLoading,
            variant: ChartLoadingPlaceholderVariant.timeSeries,
          )
        : points.isEmpty
        ? buildChartEmptyState(
            context: context,
            height: resolvedHeight,
            message: emptyMessage,
            placeholder: AgentQueryChartFailurePlaceholderContent(
              emptyMessage: emptyMessage,
              textStyle: theme.textTheme.bodyMedium,
              verticalPadding: tokens.contentSpacing,
              loadFailure: loadFailed ? loadFailure : null,
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final minChartWidth = _resolveSalesMonthlyPnlChartWidth(
                availableWidth: constraints.maxWidth,
                pointCount: points.length,
              );
              return SizedBox(
                height: resolvedHeight,
                child: ChartHorizontalScrollShell(
                  SizedBox(
                    width: minChartWidth,
                    height: resolvedHeight,
                    child: SfCartesianChart(
                      margin: EdgeInsets.zero,
                      plotAreaBorderWidth: 0,
                      onTooltipRender: buildSanitizingTooltipRenderer(),
                      tooltipBehavior: buildChartTooltipBehavior(
                        context,
                        enable: true,
                        builder: (data, point, series, pointIndex, seriesIndex) {
                          if (pointIndex < 0 || pointIndex >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final item = points[pointIndex];
                          final label = _tooltipSeriesLabel(l10n, seriesIndex);
                          final value = _tooltipSeriesValue(item, seriesIndex);
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _formatChartMonthLongLabel(item, localeTag),
                                  style: TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$label: ${AppBrFormatters.smartCompactCurrencyForLocale(value, localeTag)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      primaryXAxis: const CategoryAxis(
                        majorGridLines: MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        numberFormat: yAxisFormat,
                        axisLine: const AxisLine(width: 0),
                        majorGridLines: MajorGridLines(
                          color: gridLineColor,
                          width: 1,
                        ),
                      ),
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: chartTheme.enableSelectionZooming,
                        enablePanning: chartTheme.enableSelectionZooming,
                        enableSelectionZooming:
                            chartTheme.enableSelectionZooming,
                      ),
                      series: <CartesianSeries<SalesMonthlyPnlPoint, String>>[
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              _formatChartMonthShortLabel(point, localeTag),
                          yValueMapper: (point, _) => point.venda,
                          name: l10n.salesMonthlyPnlSeriesSalesLabel,
                          color: chartTheme.primaryColor,
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.primaryColor,
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              _formatChartMonthShortLabel(point, localeTag),
                          yValueMapper: (point, _) => point.lucro,
                          name: l10n.salesMonthlyPnlSeriesProfitLabel,
                          color: chartTheme.paletteColor(1),
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.paletteColor(1),
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              _formatChartMonthShortLabel(point, localeTag),
                          yValueMapper: (point, _) => point.custoMercadoria,
                          name: l10n.salesMonthlyPnlSeriesCostLabel,
                          color: chartTheme.paletteColor(2),
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.paletteColor(2),
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  semanticsHint: l10n.overviewComparisonBarHorizontalScrollHint,
                  key: SalesMonthlyPnlChartKeys.lineHorizontalScrollShell,
                ),
              );
            },
          );

    final shareTitle = l10n.salesMonthlyPnlChartTitle;
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: buildSalesMonthlyPnlLineChartShareMetadata(
        l10n: l10n,
        points: points,
      ),
      onRequestShare: widget.onRequestShare,
      shareEnabled: !isLoading,
    );
    final chartSurface = useChartShell
        ? AppChartShell(
            title: shareTitle,
            subtitle: l10n.salesMonthlyPnlChartSubtitle,
            onShare: shareActions.shareCallback(),
            shareProgressKey: _shareKey,
            onOpenFullscreen: onOpenFullscreen,
            child: chartBody,
          )
        : chartBody;

    return Semantics(
      label: semanticsLabel,
      child: RepaintBoundary(
        key: _shareKey,
        child: chartSurface,
      ),
    );
  }
}
